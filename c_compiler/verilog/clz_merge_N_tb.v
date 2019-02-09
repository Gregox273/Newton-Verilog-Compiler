// Count leading zeros test benches
`include "utils.vh"
`include "clz.v"

`timescale 1 ns/10 ps  // time-unit = 1 ns, precision = 10 ps

module clz_merge_N_tb;
  reg vl, vr;
  reg [0:bits_out-2] pl;
  reg [0:bits_out-2] pr;
  wire vg;
  wire [0:bits_out-1] pg;

  // duration for each bit = 20 * timescale
  localparam period = 20;
  //parameter N = 15;  // Set manually when testing
  parameter bits_out = 4;  // Set manually when testing

  clz_merge_N #(.bits_out({bits_out})) DUT (
      .vl(vl),
      .vr(vr),
      .pl(pl),
      .pr(pr),
      .vg(vg),
      .pg(pg)
    );

  initial begin
    $dumpfile("sim/clz_merge_N.vcd");
    $dumpvars;
    $monitor("%d,\t%b,\t%b,\t%b,\t%b,\t%b,\t%b",$time,vl,vr,pl,pr,vg,pg);

    vl = 1'b0;
    vr = 1'b0;
    pl = {bits_out-1{1'b1}};
    pr = {bits_out-1{1'b0}};
    #period

    vl = 1'b0;
    vr = 1'b1;
    pl = {bits_out-1{1'b1}};
    pr = {bits_out-1{1'b0}};
    #period

    vl = 1'b1;
    vr = 1'b0;
    pl = {bits_out-1{1'b1}};
    pr = {bits_out-1{1'b0}};
    #period

    vl = 1'b1;
    vr = 1'b1;
    pl = {bits_out-1{1'b1}};
    pr = {bits_out-1{1'b0}};
    #period
    $finish;
  end
endmodule  // clz_merge_N_tb
