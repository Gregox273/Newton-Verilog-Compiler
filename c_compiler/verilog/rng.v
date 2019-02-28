`include "../../submodules/iCE40-LVDS-RNG/uniform_rng.v"
`include "urng.vh"
`include "rng.vh"
`include "utils.vh"
`include "clz.v"

/*
 * Generate uniform random numbers until nonzero exponent section is reached
 */
module rng_nonzero_exp_urng (
	input wire clk, rst,
	input wire comparator_output,
	output reg [BX - 1:0] out,
	output reg valid
	);

	parameter BX = `URNG_BX;

	reg urng_rst;
	wire [BX - 1:0] urng_out;
	wire [BX - 1:0] urng_valid_vector;

	uniform_rng #(.N(BX)) urng(
		.comparator_output(comparator_output),
		.clk(clk),
		.rst(urng_rst),
		.out(urng_out),
		.valid(urng_valid_vector)
		);

	always @ ( posedge clk ) begin
		if (rst) begin
			out <= 0;
			exp_valid <= 0;
			urng_rst <= 1;
		end
		else begin
			valid <= urng_valid_vector[BX-1];
			if (urng_valid_vector[BX-1]) begin
				out <= urng_out;
				if (urng_out[BX - 3 : MANT_BW] == 0) begin
		    	// Consume another random number if exponent part is zero
		      urng_rst <= 1;
		    end
			end
			else if (urng_rst) begin
				urng_rst <= 0;
			end
		end
	end
endmodule // rng_nonzero_exp_urng

module rng_uniform_to_float(
	input clk,
	input rst,
	input [BX - 1:0] uniform,
	output reg [BX - 1:0] floating,
	output reg data_valid,
	output reg rst_urng
	);

	parameter BX = `URNG_BX;
	parameter BY = `RNG_BY;
	parameter K  = `RNG_K;
	parameter MANT_BW  = `RNG_MANT_BW;
	parameter EXP_BW   = `RNG_EXP_BW;
	parameter G_OCT = `RNG_GROWING_OCT;
	parameter D_OCT = `RNG_DIMINISHING_OCT;

	wire [`CLOG2(EXP_BW)-1:0] clz_out;
	wire clz_valid;
	wire [BX - MANT_BW - 2 : 0] exp_add_buf;
	reg [`CLOG2(`MAX(G_OCT,D_OCT))-1:0] max_exp;
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
		.pout(clz_out)
	);

	always@(posedge clk) begin
		if (rst) begin
			floating <= 0;
			data_valid <= 0;
			ready <= 0;
			max_exp <= 0;
			uniform_pipe <= 0;
		end
		else begin
			uniform_pipe <= uniform;  // delay by one clock cycle to synchronise with clz module
			if (floating[BX - 3 : MANT_BW] + clz_out > max_exp) begin
				floating[BX - 3 : MANT_BW] <= max_exp;  // Exponent
			end else begin
				floating[BX - 3 : MANT_BW] <= floating[BX - 3 : MANT_BW] + clz_out;
			end
			floating[BX - 1] <= uniform_pipe[BX - 1];  // symm
			floating[BX - 2] <= uniform_pipe[BX - 2];  // part
			floating[MANT_BW-1:0] <= uniform_pipe[MANT_BW-1:0];  // mantissa
			data_valid <= clz_valid;  // TODO: implement system to consume more random numbers if necessary (de Schryver et al)
		end
	end
endmodule  // rng_uniform_to_float

module rng_lookup(
	input clk, en
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
		if(en) begin
			c0 <= lookup_mem_c0[section_addr * 2**K + subsection_addr];
			c1 <= lookup_mem_c1[section_addr * 2**K + subsection_addr];
		end
	end

endmodule  // rng_lookup

module rng(
	input comparator_output,
	input clk, rst
	output reg [BY - 1:0] out
	);

	parameter BX = `URNG_BX;
	parameter MANT_BW  = `RNG_MANT_BW;
	parameter BY = `RNG_BY;
	parameter EXP_BW = `RNG_EXP_BW;
	parameter K = `RNG_K;
	parameter OFFSET = RNG_GROWING_OCT * (1'b1 << K);// >=RNG_GROWING_OCT * 2^RNG_K

	wire [1:0] urng_rst;  // urng can be reset by uniform_to_float or by module reset
	wire urng_rst_wire;
	assign urng_rst_wire = urng_rst[0] | urng_rst[1];

	wire [BX - 1:0] urng_out;
	wire urng_valid;

	wire [BX-1:0] float_out;
	wire float_valid;

	rng_nonzero_exp_urng #(.N(BX)) urng(
		.comparator_output(comparator_output),
		.clk(clk),
		.rst(urng_rst_wire),
		.out(urng_out),
		.valid(urng_valid)
		);

	rng_uniform_to_float #(.BX(BX), .MANT_BW(MANT_BW)) u_to_f(
		.clk(clk),
		.rst(rst),
		.uniform(urng_out),
		.floating(float_out),
		.data_valid(float_valid),
		.rst_urng(urng_rst[0])
	);

	always @ ( posedge clk ) begin
		if (rst==0) begin

		end
	end

	always @ ( posedge clk ) begin
		if (rst==0) begin

		end
	end

	always @ ( posedge clk ) begin
		if (rst) begin
			out <= 0;
			urng_rst[1] <= 1;
		end
	end
endmodule;  // rng

// module rng(
// 	input comparator_output,
// 	input clk, rst
// 	input read,
// 	output reg [BY - 1:0] out
// 	);
//
// 	parameter BX = `URNG_BX;
// 	parameter MANT_BW  = `RNG_MANT_BW;
// 	parameter BY = `RNG_BY;
// 	parameter EXP_BW = `RNG_EXP_BW;
// 	parameter K = `RNG_K;
// 	parameter OFFSET = RNG_GROWING_OCT * (1'b1 << K);// >=RNG_GROWING_OCT * 2^RNG_K
//
// 	wire [BX-1:0] urng_out;
// 	wire urng_valid;
//
// 	wire [BX-1:0] float_out;
// 	wire float_valid;
//
//
// 	wire float_part;
// 	assign float_part = float_out[MANT_BW + EXP_BW];
//
// 	wire [EXP_BW - 1:0] float_exponent;
// 	assign float_exponent = float_out[MANT_BW+EXP_BW - 1:MANT_BW];
//
// 	wire [EXP_BW:0] lookup_section_addr;
// 	assign lookup_section_addr = ( float_part == 0 )? {0,float_exponent} : float_exponent + OFFSET;  // >=RNG_GROWING_OCT * 2^RNG_K
//
// 	wire [K-1:0] lookup_subsection_addr;
// 	assign lookup_subsection_addr = float_out[MANT_BW - 1:MANT_BW - K];
//
// 	reg [BY - 1:0] lookup_c0, lookup_c1;
//
// 	rng_nonzero_exp_urng #(.BX(BX)) urng(
// 		.comparator_output(comparator_output),
// 		.clk(clk),
// 		.rst(rst),
// 		.out(urng_out),
// 		.exp_valid(urng_valid)
// 		)
//
// 	rng_uniform_to_float #(.BX(BX), .MANT_BW(MANT_BW)) u_to_f(
// 		.clk(clk),
// 		.rst(rst),
// 		.uniform(urng_out),
// 		.floating(float_out),
// 		.data_valid(float_valid)
// 	);
//
// 	rng_lookup lookup(
// 		//.clk(read),
// 		.clk(clk),
// 		.en(float_valid),
// 		.section_addr(lookup_section_addr),
// 		.subsection_addr(lookup_subsection_addr),
// 		.c0(lookup_c0),
// 		.c1(lookup_c1)
// 	);
//
// 	always @ ( posedge clk ) begin
// 		if (rst) begin
// 			out <= 0;
// 			lookup_c0 <= 0;
// 			lookup_c1 <= 0;
// 		end
// 		else begin
// 			out <= lookup_c0 + lookup_c1 * float_out[];  // TODO: use hardware multiplier (SB_MAC16) if possible
// 		end
// 	end;
// endmodule;
