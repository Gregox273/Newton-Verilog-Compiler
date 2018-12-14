// RNG parameters

`ifndef _rng_vh_
`define _rng_vh_

`include "urng.vh"

`define RNG_BY 16
`define RNG_K 4
`define RNG_MANT_BW 8
`define RNG_EXP_PART (URNG_BX - RNG_MANT_BW - 2)  // Uniform random input
`define RNG_EXP_BW (RNG_BY - RNG_MANT_BW - 2)  // Floating point output

`endif // _rng_vh_
