// Count leading zeros test benches
`include "utils.vh"
`include "clz.v"

`timescale 1 ns/10 ps  // time-unit = 1 ns, precision = 10 ps

module clz_tb;
  reg [bits_in-1:0] in;
  reg clk, rst;
  wire [bits_out-1:0] out;
  wire valid;
  wire ready;

  localparam period = 20;
  localparam delay = 5;
  parameter half_bits_in = 8;
  parameter bits_in = 16;
  parameter bits_out = 4;

  clz_clk #(.bits_in({bits_in})) TI (  // Test Instance
    .b(in),
    .clk(clk),
    .rst(rst),
    .pout(out),
    .vout(valid)
  );

  // Reset then set up clock
  initial begin
    clk = 1'b0;
    rst = 1'b1;
    repeat(3) #period clk = ~clk;
    rst = 1'b0;
    forever #period clk = ~clk;
  end

  initial begin
    $dumpfile("sim/clz.vcd");
    $dumpvars;
    $monitor("%d,\t%b,\t%b,\t%b,\t%b",$time,clk,in,out,valid);

    in = {bits_in{1'b0}};  // init
    @(negedge rst);  // wait for reset
    @(posedge clk);
    #delay
    in = {bits_in{1'b1}};
    @(posedge clk);

    #delay
    in = {{half_bits_in{1'b0}},{half_bits_in{1'b1}}};
    @(posedge clk);

    #delay
    in = {{half_bits_in{1'b1}},{half_bits_in{1'b0}}};
    @(posedge clk);

    #delay
    in = {{bits_in-1{1'b0}},1'b1};
    repeat(2) @(posedge clk);
    $finish;
  end
endmodule  // clz_tb
