`include "rng.v"

`timescale 1 ns/10 ps  // time-unit = 1 ns, precision = 10 ps

module rng_uniform_to_float_tb;
  reg clk, rst, uniform_valid;
  reg [] uniform;
  wire floating, data_valid;

  localparam period = 20;
  localparam delay = 5;

  // Reset then set up clock
  initial begin
    clk = 1'b0;
    rst = 1'b1;
    repeat(3) #period clk = ~clk;
    rst = 1'b0;
    forever #period clk = ~clk;
  end

  initial begin
    $dumpfile("sim/rng_uniform_to_float.vcd");
    $dumpvars;
    $monitor("%d,\t%b,\t%b,\t%b,\t%b,\t%b",$time,clk,uniform_valid,uniform,floating,data_valid);

    uniform = {bits_in{1'b0}};  // init
    @(negedge rst);  // wait for reset
    @(posedge clk);
    #delay
    in = {bits_in{1'b1}};
    @(posedge clk);
  end
endmodule