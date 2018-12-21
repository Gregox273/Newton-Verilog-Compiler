`include "urng.vh"
`include "rng.vh"
`include "utils.vh"
`include "clz.v"

module rng_uniform_to_float(
	input clock,
	input rst,
	input [BX - 1:0] uniform,
	output reg [BX - 1:0] floating,
	output reg data_valid);

	parameter BX = `URNG_BX;
	parameter BY = `RNG_BY;
	parameter K  = `RNG_K;
	parameter MANT_BW  = `RNG_MANT_BW;
	parameter EXP_BW   = `RNG_EXP_BW;
	parameter G_OCT = `RNG_GROWING_OCT;
	parameter D_OCT = `RNG_DIMINISHING_OCT;

	wire [`CLOG2(EXP_BW):0] clz_out;
	wire [BX - MANT_BW - 2 : 0] exp_add_buf;
	wire [`CLOG2(`MAX(G_OCT,D_OCT))-1:0] max_exp;

	//assign max_exp = ( == 1) ? D_OCT : G_OCT ;  // Depends on part bit
	always@(uniform[BX - 2]) begin
		if(uniform[BX - 2] == 1) begin
			max_exp = D_OCT;
		end else begin
			max_exp = G_OCT;
		end
	end

	clz #(.half_bits_in(EXP_BW/2)) count_leading_zeros (
		.in(uniform[BX - 3 : MANT_BW]),
		.out(clz_out[`CLOG2(EXP_BW)-1:0]),
		.valid(~clz_out[`CLOG2(EXP_BW)])
	);

	// always@(clz_out) begin
	// 	if (clz_valid) begin
	// 		exp_add_buf = clz_out;
	// 	end else begin
	// 		exp_add_buf = EXP_BW;
	// 	end
	// end

	always@(posedge clock or posedge rst)
		if (rst == 1) begin
			floating <= 0;
		end else begin
			// if (clz_valid == 1) begin
			// 	floating[BX - 3 : MANT_BW] <= clz_out + floating[BX - 3 : MANT_BW];  // Exponent
			// end else begin
			//
			// end
			if (floating[BX - 3 : MANT_BW] + clz_out > max_exp) begin
				floating[BX - 3 : MANT_BW] <= max_exp;  // Exponent
			end else begin
				floating[BX - 3 : MANT_BW] <= floating[BX - 3 : MANT_BW] + clz_out;
			end
			floating[BX - 1] <= uniform[BX - 1];  // symm
			floating[BX - 2] <= uniform[BX - 2];  // part
			floating[MANT_BW-1:0] <= uniform[MANT_BW-1:0]; 			  // mantissa
			data_valid <= clz_valid;
		end

endmodule  // rng_uniform_to_float

module rng_lookup(
	input clock,
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

	always@(posedge clock) begin
		c0 <= lookup_mem_c0[section_addr * 2**K + subsection_addr];
		c1 <= lookup_mem_c1[section_addr * 2**K + subsection_addr];
	end

endmodule  // rng_lookup

// module rng(
//
// 	);
//
// 	rng_uniform_to_float u_to_f(
// 		.clock(),
// 		.rst(),
// 		.uniform(),
// 		floating(),
// 		data_valid()
// 	);
//
// 	rng_lookup lookup(
// 		.clock(),
// 		.section_addr(),
// 		.subsection_addr(),
// 		.c0(),
// 		.c1()
// 	);
// endmodule;
