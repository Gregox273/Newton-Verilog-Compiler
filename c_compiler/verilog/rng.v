`include "../../submodules/iCE40-LVDS-RNG/uniform_rng.v"
`include "urng.vh"
`include "rng.vh"
`include "utils.vh"
`include "clz.v"

module rng_uniform_to_float(
	input clk,
	input rst,
	input uniform_valid,
	input [BX - 1:0] uniform,
	output reg [BX - 1:0] floating,
	output reg data_valid,
	output reg ready);

	parameter BX = `URNG_BX;
	parameter BY = `RNG_BY;
	parameter K  = `RNG_K;
	parameter MANT_BW  = `RNG_MANT_BW;
	parameter EXP_BW   = `RNG_EXP_BW;
	parameter G_OCT = `RNG_GROWING_OCT;
	parameter D_OCT = `RNG_DIMINISHING_OCT;

	wire [`CLOG2(EXP_BW)-1:0] clz_out;
	wire clz_valid, clz_rdy;
	wire [BX - MANT_BW - 2 : 0] exp_add_buf;
	reg [`CLOG2(`MAX(G_OCT,D_OCT))-1:0] max_exp;
	reg [BX - 1:0] uniform_buf;
	reg [BX - 1:0] uniform_pipe;

	//assign max_exp = ( == 1) ? D_OCT : G_OCT ;  // Depends on part bit
	always@(uniform_pipe[BX - 2]) begin
		if(uniform_pipe[BX - 2] == 1) begin
			max_exp = D_OCT;
		end else begin
			max_exp = G_OCT;
		end
	end

	clz_clk #(.bits_in(EXP_BW)) count_leading_zeros (
		.b(uniform_buf[BX - 3 : MANT_BW]),
		.clk(clk),
		.rst(rst),
		.vout(clz_valid),
		.pout(clz_out),
		.ready(clz_rdy)
	);

	always@(posedge rst) begin
		floating <= 0;
		data_valid <= 0;
		ready <= 0;
		max_exp <= 0;
		uniform_buf <= 0;
		uniform_pipe <= 0;
	end

	always@(posedge clz_rdy)
		ready <= 0;  // antiphase with clz_rdy

		if (floating[BX - 3 : MANT_BW] + clz_out > max_exp) begin
			floating[BX - 3 : MANT_BW] <= max_exp;  // Exponent
		end else begin
			floating[BX - 3 : MANT_BW] <= floating[BX - 3 : MANT_BW] + clz_out;
		end
		floating[BX - 1] <= uniform_pipe[BX - 1];  // symm
		floating[BX - 2] <= uniform_pipe[BX - 2];  // part
		floating[MANT_BW-1:0] <= uniform_pipe[MANT_BW-1:0];  // mantissa
		data_valid <= clz_valid;
		uniform_pipe <= uniform_buf;

		// clz module ready for new input
		if (uniform_valid) begin
			// If new input is ready
			uniform_buf <= uniform;
		end
	end

	always @ ( negedge clz_rdy ) begin
		ready <= 1;  // antiphase with clz_ready
	end

endmodule  // rng_uniform_to_float

module rng_lookup(
	input clk,
	input [EXP_BW:0] section_addr,
	input[K-1:0] subsection_addr,
	output reg [BY - 1:0] c0, c1
	);

	parameter EXP_BW   = `RNG_EXP_BW;
	parameter K  = `RNG_K;
	parameter BY = `RNG_BY;
	parameter G_OCT = `RNG_GROWING_OCT;
	parameter D_OCT = `RNG_DIMINISHING_OCT;

	reg [BY-1:0] lookup_mem_c0 [0:(G_OCT+D_OCT)*2**K - 1];
	reg [BY-1:0] lookup_mem_c1 [0:(G_OCT+D_OCT)*2**K - 1];

	initial begin
		$readmemh("c0.mem", lookup_mem_c0);
		$readmemh("c1.mem", lookup_mem_c1);
	end

	always@(posedge clk) begin
		c0 <= lookup_mem_c0[section_addr * 2**K + subsection_addr];
		c1 <= lookup_mem_c1[section_addr * 2**K + subsection_addr];
	end

endmodule  // rng_lookup

module rng(
	input comparator_output,
	input clk,
	input read
	);

	wire urng_rst;
	wire [`URNG_BX-1:0] urng_out;
	wire [`URNG_BX-1:0] urng_valid;
	wire float_rst;
	wire [`URNG_BX-1:0] float_out;
	wire float_valid;
	reg [`RNG_BY - 1:0] c0, c1;

	uniform_rng #(.N(`URNG_BX)) urng(
		.comparator_output(comparator_output),
		.clk(clk),
		.rst(urng_rst),
		.out(urng_out),
		.valid(urng_valid)
	);

	// always @ ( posedge urng_valid[`URNG_BX-1] ) begin
	// 	// New uniform random number is ready
	// 	urng_out_buf <= urng_out;
	// end

	rng_uniform_to_float u_to_f(
		//.clk(urng_valid[`URNG_BX-1]),  // Convert uniform random number once it has been completely generated
		.clk(clk),
		.rst(float_rst),
		.uniform_valid(urng_valid[`URNG_BX-1]),
		.uniform(urng_out),
		.floating(float_out),
		.data_valid(float_valid)
	);

	rng_lookup lookup(
		.clk(read),
		.section_addr(),[EXP_BW:0]
		.subsection_addr(),[K-1:0]
		.c0(c0),
		.c1(c1)
	);
endmodule;
