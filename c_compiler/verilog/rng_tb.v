`include "utils.vh"
`include "rng.v"
`include "rng.vh"

`timescale 1 ns/10 ps  // time-unit = 1 ns, precision = 10 ps

module rng_tb;
  reg bits_in, clk, rst;
  wire [BY - 1:0] out;
  wire valid;

  localparam period = 20;
  localparam delay = 5;

  parameter BY = `RNG_BY;
  parameter BX = `URNG_BX;
  integer i, j;

  rng TI(
    .clk(clk),
    .rst(rst),
    .bits_in(bits_in),
    .rng(out),
    .valid(valid)
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
    $dumpfile("sim/rng.vcd");
    $dumpvars;
    $monitor("%d,\t%b,\t%b,\t%b,\t%b",$time,clk,bits_in,out ,valid);

    bits_in = 1'b0;  // init
    @(negedge rst);  // wait for reset
    @(posedge clk);

    for (i = 0; i < 2**BX; i = i + 1) begin
      #(period*2) bits_in = ~bits_in;
    end
    // for (i = 0; i < 2**BX; i = i + 1) begin
    //   for (j = 0; j < BX; j = j + 1) begin
    //     #delay
    //     bits_in = i[j];
    //     @(posedge clk);
    //   end
    // end

    //
    // #delay
    // in = {{half_bits_in{1'b0}},{half_bits_in{1'b1}}};
    // @(posedge clk);
    //
    // #delay
    // in = {{half_bits_in{1'b1}},{half_bits_in{1'b0}}};
    // @(posedge clk);
    //
    // #delay
    // in = {{bits_in-1{1'b0}},1'b1};
    // repeat(2) @(posedge clk);
    $finish;
  end
endmodule  // rng_tb
