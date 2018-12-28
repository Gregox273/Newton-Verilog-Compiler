// Based on work by Mehrdad Majzoobi,Farinaz Koushanfar & Srinivas Devadas
// "FPGA-based True Random Number Generation using Circuit Metastability with
//    Adaptive Feedback Control"
`include "urng.vh"

module fine_pdl(
  input wire i /* synthesis keep */,
  input wire c /* synthesis keep */,
  output wire o /* synthesis keep */);
  SB_LUT4 #(.LUT_INIT('b1010101010101010)) lut4 (
    .O(o),
    .I0(false),  // Closest to output
    .I1(false),
    .I2(c),
    .I3(i),  // Closest to SRAM values
  );
endmodule  // fine_pdl

module coarse_pdl(
  input wire i /* synthesis keep */,
  input wire c /* synthesis keep */,
  output wire o /* synthesis keep */);
  SB_LUT4 #(.LUT_INIT('b1010101010101010)) lut4 (
    .O(o),
    .I0(c),  // Closest to output
    .I1(c),
    .I2(c),
    .I3(i),  // Closest to SRAM values
  );
endmodule  // coarse_pdl

module test(
  input i,
  input [1:0] c,
  output o);
  wire internal;
  coarse_pdl cpdl(
    .i(i),
    .c(c[0]),
    .o(internal),
    );

  fine_pdl fpdl(
    .i(internal),
    .c(c[1]),
    .o(o)
    );
endmodule  // test
