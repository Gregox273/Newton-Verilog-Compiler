// Count leading zeros
// Source:
//    V. Oklobdzija, “An Implementation Algorithm and Design of a Novel
//    Leading Zero Detector Circuit”, 26th IEEE Asilomar Conference on Signals,
//    Systems, and Computers, 1992, pp. 391- 395.
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
  output v_out,
  output p_out);

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
 * N-bit layer of LZD hierarchy
 *
 * vl -- left valid input
 * vr -- right valid input
 * pl -- left position input
 * pr -- right position input
 *
 * vg -- output valid bit
 * pg -- output position bits
 *
 * N  -- dimension of this hierarchical layer (output has width log2(N))
 */
module clz_merge_N(
  input vl,
  input vr,
  input [0:bits_out-2] pl,
  input [0:bits_out-2] pr,
  output vg,
  output [0:bits_out-1] pg);

  parameter N = 4;
  localparam bits_out = `CLOG2(N);

  always@* begin
    vg = vl | vr;
    if (vl == 1) begin
      pg = {0,pl};
    end else begin
      // vr == 1 or vg == 0 so don't care
      pg = {1,pr};
    end
  end
endmodule  // clz_merge_N

/*
 * Leading zero counter
 *
 * in      -- input (bits to count)
 *
 * out     -- count output
 * valid   -- output valid bit (invalid if overflow)
 *
 * bits_in -- bit width of input
 */
module clz(
  input [bits_in-1:0] in,
  output [bits_out-1:0] out,
  output valid);

  parameter bits_in = 4;
  localparam half_bits_in = 0.5*bits_in;
  localparam bits_out = `CLOG2(bits_in);

  // Generate the necessary wires
  genvar i_wN;
  generate
    for(i_wN = 0; i_wN < bits_out; i_wN = i_wN + 1) begin : lzd_wN
        wire [0:half_bits_in/(2**i_wN)] v;
        wire [0:(i_wN + 1)*half_bits_in/(2**i_wN)] p;
    end
  endgenerate

  assign valid = lzd_wN[bits_out-1].v[0];
  assign out = lzd_wN[bits_out-1].p;

  // Generate 2 bit leading zero detectors
  genvar i_lzd2;
  generate
    for(i_lzd2 = 0; i_lzd2 < half_bits_in; i_lzd2 = i_lzd2 + 1) begin : lzd2
      clz_encode clz_en (
        .in(in[i_lzd2*2+1:i_lzd2*2]),
        .v_out(lzd_wN[0].v[i_lzd2]),
        .p_out(lzd_wN[0].p[i_lzd2])
      );
    end
  endgenerate

  // Generate N bit lzd blocks
  genvar i_N, i_Nx;
  generate
    for(i_N = 1; i_N < bits_out; i_N = i_N + 1) begin : lzd_N
      for(i_Nx = 0; i_Nx < half_bits_in/(2**i_N); i_Nx = i_Nx + 1) begin : lzd_Nx
        clz_merge_N #(.N({i_N})) clz_Nx (  // 2**(I_N+1)
            .vl(lzd_wN[i_N-1].v[2*i_Nx]),
            .vr(lzd_wN[i_N-1].v[2*i_Nx+1]),
            .pl(lzd_wN[i_N-1].v[(2*i_N*i_Nx) : (2*i_N*i_Nx + i_N - 1)]),
            .pr(lzd_wN[i_N-1].v[2*i_N*i_Nx + i_N : 2*i_N*i_Nx + 2*i_N - 1]),
            .vg(lzd_wN[i_N].v[i_Nx]),
            .pg(lzd_wN[i_N].p[(i_N+1)*i_Nx : (i_N+1)*(i_Nx+1)-1])
          );
      end
    end
  endgenerate
endmodule  // clz
