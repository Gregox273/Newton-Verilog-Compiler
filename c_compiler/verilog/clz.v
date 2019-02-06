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
  output v_out,
  output p_out);

  always@*
    case(in)
        2'b00   : begin
                    v_out <= 1'b0;
                    p_out <= 1'b0;
                  end
        2'b01   : begin
                    v_out <= 1'b1;
                    p_out <= 1'b1;
                  end
        default : begin
                    v_out <= 1'b1;
                    p_out <= 1'b0;
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
  output vg,
  output [0:bits_out-1] pg);

  parameter bits_out = 2;

  always@* begin
    vg <= vl | vr;
    if (vl == 1) begin
      pg <= {0,pl};
    end else begin
      // vr == 1 or vg == 0 so don't care
      pg <= {1,pr};
    end
  end
endmodule  // clz_merge_N

/*
 * Nth layer of LZD circuit
 *
 * vin  -- input valid bits
 * pin  -- input position bits
 * vout -- output valid bits
 * pout -- output position bits
 *
 * half_bits_in -- 0.5 * number of input bits to the LZD circuit
 * N            -- index of this hierarchical layer
 */
module clz_layer_N(
  input [0 +: num_vin] vin,
  input [0 +: num_pin] pin,
  output [0 +: num_vout] vout,
  output [0 +: num_pout] pout);

  parameter half_bits_in = 4;
  parameter N = 1;
  localparam  Nx = half_bits_in/(2**N);  // Number of units in layer
  localparam num_vin = half_bits_in/(2**(N-1));
  localparam num_pin = N*num_vin;
  localparam num_vout = half_bits_in/(2**N);
  localparam num_pout = (N+1)*half_bits_in/(2**N);
  // N position bits in, N+1 position bits out

  /*
   * Generate LZD units within the layer
   *
   *i_Nx -- index of unit within the layer
   */
  genvar i_Nx;
  generate
    for(i_Nx = 0; i_Nx < Nx; i_Nx = i_Nx + 1) begin : lzd_layer_N
      clz_merge_N #(.bits_out(N+1)) clz_Nx (
        .vl(vin[i_Nx*2]),
        .vr(vin[i_Nx*2+1]),
        .pl(pin[i_Nx*2*N +: N]),
        .pr(pin[i_Nx*2*N+N +: N]),
        .vg(vout[i_Nx]),
        .pg(pout[i_Nx*(N+1) +: N+1])
      );
    end
  endgenerate
endmodule  // clz_layer_N

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

  /* Generate the necessary wires
   *
   * i_wN -- hierarchical layer of wires being generated
   *         = 1 at the outputs to the two bit LZD units
   *         = bits_out-1 at the module output
   * i_pN -- index of position bit wire
   */
  genvar i_wN, i_pN;
  generate
    for(i_wN = 0; i_wN < bits_out; i_wN = i_wN + 1) begin : lzd_wN
      wire v[0:half_bits_in/(2**i_wN)-1];
      wire p[0:(i_wN + 1)*half_bits_in/(2**i_wN)-1];

      // If at the output level of the hierarchy, map wires to output
      if (i_wN == bits_out-1) begin
        assign valid = lzd_wN[i_wN].v[0];
        for(i_pN = 0; i_pN < bits_out; i_pN = i_pN + 1) begin : lzd_wN_pN
          // TODO: check endianness is right way round
          assign out[bits_out-1-i_pN] = lzd_wN[i_wN].p[i_pN];
        end
      end
    end
  endgenerate

  /* Generate 2 bit leading zero detectors
   *
   * i_lzd2 -- index of 2 bit LZD
   */
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

  genvar i_N, i_Nx;  //  Layer index and index within the layer
  generate
    for(i_N = 1; i_N < bits_out; i_N = i_N + 1) begin : lzd_layer_N
      localparam num_vin = half_bits_in/(2**(i_N-1));
      localparam num_pin = (i_N-1)*(half_bits_in/(2**(i_N-1)));
      localparam num_vout = half_bits_in/(2**i_N);
      localparam num_pout = i_N*half_bits_in/(2**i_N);
      wire [0 +: num_vin] vin;
      wire [0 +: num_pin] pin;
      wire [0 +: num_vout] vout;
      wire [0 +: num_pout] pout;

      for(i_Nx = 0; i_Nx < num_vin; i_Nx = i_Nx + 1) begin : lzd_layer_N_vin_x
        assign lzd_layer_N[i_N].vin[i_Nx] = lzd_wN[i_N-1].v[i_Nx];
      end

      for(i_Nx = 0; i_Nx < num_pin; i_Nx = i_Nx + 1) begin : lzd_layer_N_pin_x
        assign pin[i_Nx] = lzd_wN[i_N-1].p[i_Nx];
      end

      for(i_Nx = 0; i_Nx < num_vout; i_Nx = i_Nx + 1) begin : lzd_layer_N_vout_x
        assign vout[i_Nx] = lzd_wN[i_N].v[i_Nx];
      end

      for(i_Nx = 0; i_Nx < num_pout; i_Nx = i_Nx + 1) begin : lzd_layer_N_pout_x
        assign pin[i_Nx] = lzd_wN[i_N].p[i_Nx];
      end

      clz_layer_N #(.half_bits_in(half_bits_in),
                    .N(i_N)) clz_N (
        .vin(vin),
        .pin(pin),
        .vout(vout),
        .pout(pout)
        );
    end
  endgenerate

  // /* Generate N bit lzd blocks
  // *
  // * i_N  -- hierarchical layer being generated
  // * i_Nx -- index of module within hierarchical layer i_N
  // */
  // genvar i_N, i_Nx;
  // generate
  //   for(i_N = 1; i_N < bits_out; i_N = i_N + 1) begin : lzd_N
  //     for(i_Nx = 0; i_Nx < half_bits_in/(2**i_N); i_Nx = i_Nx + 1) begin : lzd_Nx
  //       if(i_N == 1) begin
  //         clz_merge_N #(.bits_out(i_N+1)) clz_Nx (  // 2**(I_N+1)
  //           .vl(lzd_wN[i_N-1].v[2*i_Nx]),
  //           .vr(lzd_wN[i_N-1].v[2*i_Nx+1]),
  //           .pl(lzd_wN[i_N-1].p[2*i_N*i_Nx]),
  //           .pr(lzd_wN[i_N-1].p[2*i_N*i_Nx + i_N]),
  //           .vg(lzd_wN[i_N].v[i_Nx]),
  //           .pg(lzd_wN[i_N].p[(i_N+1)*i_Nx : (i_N+1)*(i_Nx+1)-1])
  //         );
  //       end
  //       else begin
  //         clz_merge_N #(.N(i_N+1)) clz_Nx (  // 2**(I_N+1)
  //           .vl(lzd_wN[i_N-1].v[2*i_Nx]),
  //           .vr(lzd_wN[i_N-1].v[2*i_Nx+1]),
  //           .pl(lzd_wN[i_N-1].p[(2*i_N*i_Nx) : (2*i_N*i_Nx + i_N - 1)]),
  //           .pr(lzd_wN[i_N-1].p[2*i_N*i_Nx + i_N : 2*i_N*i_Nx + 2*i_N - 1]),
  //           .vg(lzd_wN[i_N].v[i_Nx]),
  //           .pg(lzd_wN[i_N].p[(i_N+1)*i_Nx : (i_N+1)*(i_Nx+1)-1])
  //         );
  //       end
  //     end
  //   end
  // endgenerate
endmodule  // clz
