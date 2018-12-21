`ifndef _utils_vh_
`define _utils_vh_

// Base 2 log
// Source:
//  Jonathan Mayer, stackoverflow (https://stackoverflow.com/questions/5269634/address-width-from-ram-depth)
`define CLOG2(x) \
   (x <= 2) ? 1 : \
   (x <= 4) ? 2 : \
   (x <= 8) ? 3 : \
   (x <= 16) ? 4 : \
   (x <= 32) ? 5 : \
   (x <= 64) ? 6 : \
   (x <= 128) ? 7 : \
	 (x <= 256) ? 8 : \
   -1

 // Max
 `define MAX(x,y) (x)>(y)?(x):(y)

 `endif  // _utils_vh_
