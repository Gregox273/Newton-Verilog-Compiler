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
  parameter N = 15;  // Set manually when testing
  parameter bits_out = 4;  // Set manually when testing

  clz_merge_N #(.N({N})) TI (  // Test Instance
      .vl(vl),
      .vr(vr),
      .pl(pl),
      .pr(pr),
      .vg(vg),
      .pg(pg)
    );

  initial begin
    $dumpfile("dump/clz_merge_N.vcd")
    $monitor("%d,\t%b,\t%b",$time,vg,pg);

    vl = 1'b0;
    vr = 1'b0;
    pl = (bits_out-1)'b1;
    pr = (bits_out-1)'b0;
    #period

    vl = 1'b0;
    vr = 1'b1;
    pl = (bits_out-1)'b1;
    pr = (bits_out-1)'b0;
    #period

    vl = 1'b1;
    vr = 1'b0;
    pl = (bits_out-1)'b1;
    pr = (bits_out-1)'b0;
    #period

    vl = 1'b1;
    vr = 1'b1;
    pl = (bits_out-1)'b1;
    pr = (bits_out-1)'b0;
    #period
  end
endmodule  // clz_merge_N_tb

module clz_tb;

  reg [bits_in-1:0] in;
  wire [bits_out-1:0] out;
  wire valid;

  parameter half_bits_in = 8;
  parameter bits_in = 16;
  parameter bits_out = 4;

  clz #(.bits_in({bits_in})) TI (  // Test Instance
    .b(in),
    .pout(out),
    .vout(valid)
  );

  initial begin
    $dumpfile("dump/clz.vcd")
    $monitor("%d,\t%b,\t%b,\t%b",$time,in,out,valid);

    in = bits_in'b0;
    #period

    in = bits_in'b1;
    #period

    in = ~(bits_in'b(half_bits_in));
    #period

    in = bits_in'b(half_bits_in);
    #period
  end
endmodule  // clz_tb
