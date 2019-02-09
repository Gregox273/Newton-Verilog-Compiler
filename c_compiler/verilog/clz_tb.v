// Count leading zeros test benches
`include "utils.vh"
`include "clz.v"

`timescale 1 ns/10 ps  // time-unit = 1 ns, precision = 10 ps

module clz_tb;
  reg [bits_in-1:0] in;
  wire [bits_out-1:0] out;
  wire valid;

  localparam period = 20;
  parameter half_bits_in = 8;
  parameter bits_in = 16;
  parameter bits_out = 4;

  clz #(.bits_in({bits_in})) TI (  // Test Instance
    .b(in),
    .pout(out),
    .vout(valid)
  );

  initial begin
    $dumpfile("sim/clz.vcd");
    $dumpvars;
    $monitor("%d,\t%b,\t%b,\t%b",$time,in,out,valid);

    in = {bits_in{1'b0}};
    #period

    in = {bits_in{1'b1}};
    #period

    in = {{half_bits_in{1'b0}},{half_bits_in{1'b1}}};
    #period

    in = {{half_bits_in{1'b1}},{half_bits_in{1'b0}}};
    #period

    in = {{bits_in-1{1'b0}},1'b1};
    #period
    $finish;
  end
endmodule  // clz_tb
