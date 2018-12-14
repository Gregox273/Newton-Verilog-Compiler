`include "urng.vh"
`include "rng.vh"
`include "clog2.vh"
`include "clz.v"

module rng_uniform_to_float(
	input clock,
	input [`RNG_BY - 1:0] uniform,
	output reg [`RNG_BY - 1:0] floating,
	output data_valid);

	parameter BY = `RNG_BY;
	parameter K  = `RNG_K;
	parameter MANT_BW  = `RNG_MANT_BW;
	parameter EXP_PART = `RNG_EXP_PART;  // Uniform random input
	parameter EXP_BW   = `RNG_EXP_BW;   // Floating point output

	assign uniform = floating;

endmodule  // rng_uniform_to_float
