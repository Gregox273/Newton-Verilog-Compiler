/* Count leading zeros
 * Source:
 *    V. Oklobdzija, “An Implementation Algorithm and Design of a Novel
 *    Leading Zero Detector Circuit”, 26th IEEE Asilomar Conference on Signals,
 *    Systems, and Computers, 1992, pp. 391- 395.
 *
 * Block diagram is in project notebook (13th December)
 */
`include "utils.vh"
//`include "rng.vh"

/*
 * Two-bit LZD unit
 *
 * in    -- input pattern
 * v_out -- valid bit
 * p_out -- position bit
 */
module clz_encode(
  input [1:0] in,
  output reg v_out,
  output reg p_out);

  always@*
    case(in)
        2'b00   : begin
                    v_out = 1'b0;
                    p_out = 1'b0;
                  end
        2'b01   : begin
                    v_out = 1'b1;
                    p_out = 1'b1;
                  end
        default : begin
                    v_out = 1'b1;
                    p_out = 1'b0;
                  end
    endcase
endmodule  // clz_encode

/*
 * N bit LZD unit
 *
 * vl -- left valid input
 * vr -- right valid input
 * pl -- left position input
 * pr -- right position input
 *
 * vg -- output valid bit
 * pg -- output position bits
 *
 * bits_out  -- number ofposition bits at output
 */
module clz_merge_N(
  input vl,
  input vr,
  input [0:bits_out-2] pl,
  input [0:bits_out-2] pr,
  output reg vg,
  output reg [0:bits_out-1] pg);

  parameter bits_out = 2;

  always@* begin
    vg = (vl || vr);
    if (vl == 1) begin
      pg = {1'b0,pl};
    end else begin
      // vr == 1 or vg == 0 so don't care
      pg = {1'b1,pr};
    end
  end
endmodule  // clz_merge_N

/*
 * Nth layer of LZD circuit. Recursively build tree structure.
 *
 * b  -- input bits
 * vout -- output valid bits
 * pout -- output position bits
 *
 * bits_in -- number of input bits to the LZD circuit
 */
module clz(
  input [0 : bits_in-1] b,
  output vout,
  output [0 : bits_out-1] pout);

  parameter bits_in = 8;
  localparam modified_bits_in = (bits_in % 2) ? bits_in + 1 : bits_in;
  localparam half_bits_in = modified_bits_in/2;
  localparam bits_out = `CLOG2(bits_in);

  wire [0 : modified_bits_in - 1] modified_b;
  wire [0 : half_bits_in - 1] input_l, input_r;
  wire vl, vr;
  wire [0 : bits_out-2] pl, pr;

  // if (bits_in % 2) begin
  //   // If input is an odd number of bits, convert to even number for the tree structure
  //   assign modified_b[0: modified_bits_in - 2] = b;
  //   assign modified_b[modified_bits_in - 1] = 1;
  // end
  // else begin
  //   assign modified_b = b;
  // end

  assign modified_b[0: modified_bits_in - 2] = b;
  assign modified_b[modified_bits_in - 1] = 0;

  assign input_l = modified_b[0 +: half_bits_in];
  assign input_r = modified_b[half_bits_in +: half_bits_in];

  if(bits_out <= 1) begin
    clz_encode clz (
      .in(modified_b),
      .v_out(vout),
      .p_out(pout)
    );
  end
  else begin
    if(bits_out <= 2) begin
      // If this module must contain 2-bit encoders
      clz_encode clz_l (
        .in(input_l),
        .v_out(vl),
        .p_out(pl)
      );

      clz_encode clz_r (
        .in(input_r),
        .v_out(vr),
        .p_out(pr)
      );
    end
    else begin
      clz #(.bits_in(half_bits_in)) clz_l (
        .b(b[0 +: half_bits_in]),
        .vout(vl),
        .pout(pl)
      );

      clz #(.bits_in(half_bits_in)) clz_r (
        .b(b[half_bits_in +: half_bits_in]),
        .vout(vr),
        .pout(pr)
      );
    end

    clz_merge_N #(.bits_out(bits_out)) clz_Nx (
      .vl(vl),
      .vr(vr),
      .pl(pl),
      .pr(pr),
      .vg(vout),
      .pg(pout)
    );
  end
endmodule  // clz

/*
 * Clocked version of clz, used to reduce critical path length
 */
module clz_clk(
  input [0 : bits_in-1] b,
  input clk,
  input rst,
  output reg vout,
  output reg [0 : bits_out-1] pout
  );

  parameter bits_in = 8;
  localparam bits_out = `CLOG2(bits_in);

  wire w_vout;
  wire [0 : bits_out - 1] w_pout;

  clz #(.bits_in(bits_in)) clz_combinational (
    .b(b),
    .vout(w_vout),
    .pout(w_pout)
  );

  always @(posedge clk) begin
    if(rst) begin
      vout <= 0;
      pout <= 0;
    end
    else begin
      vout <= w_vout;
      pout <= w_pout;
    end
  end

endmodule  // clz_clk
