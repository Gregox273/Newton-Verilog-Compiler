// RNG parameters

`ifndef _rng_vh_
`define _rng_vh_

`include "urng.vh"

`define RNG_BY 16
`define RNG_K 4
`define RNG_MANT_BW 8
`define RNG_EXP_BW `URNG_BX - `RNG_MANT_BW - 2
`define RNG_GROWING_OCT 3
`define RNG_DIMINISHING_OCT 2

`endif // _rng_vh_
