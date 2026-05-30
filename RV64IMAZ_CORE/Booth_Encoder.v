`timescale 1ns / 1ps

module Booth_Encoder #(
    parameter W = 64                             // operand width (must be even)
)(
    input  wire signed [W-1:0]      M,           // multiplicand (signed)
    input  wire signed [W-1:0]      Q,           // multiplier   (signed)
    output wire [(W/2)*(2*W)-1:0]   PP           // [FIXED] Flattened 1D array
);

    localparam NUM_PP = W / 2;                   // number of partial products (32 for W=64)
    localparam PW     = 2 * W;                   // product width (128 for W=64)

    wire signed [PW-1:0] M_se = {{W{M[W-1]}}, M};

    wire unused_cout_neg;                        // suppress Verilator warning

    wire signed [PW-1:0] PP_zero   = {PW{1'b0}};
    wire signed [PW-1:0] PP_pos_M  = M_se;
    wire signed [PW-1:0] PP_neg_M;

    KSA #(.N(PW)) ksa_neg (
        .a   (~M_se),
        .b   ({PW{1'b0}}),
        .cin (1'b1),
        .sum (PP_neg_M),
        .cout(unused_cout_neg)
    );

    wire signed [PW-1:0] PP_pos_2M = M_se    << 1;
    wire signed [PW-1:0] PP_neg_2M = PP_neg_M << 1;

    // [FIXED] Sized to exactly W:0 to prevent the unused 65th-bit warning
    wire [W:0] Q_ext;
    assign Q_ext = {Q, 1'b0};

    genvar i;
    generate
        for (i = 0; i < NUM_PP; i = i + 1) begin : gen_booth

            wire [2:0] win = Q_ext[2*i +: 3];

            wire [PW-1:0] ppf =
                win[2] ? (win[1] ? (win[0] ? PP_zero    : PP_neg_M )
                                 : (win[0] ? PP_neg_M   : PP_neg_2M))
                       : (win[1] ? (win[0] ? PP_pos_2M  : PP_pos_M )
                                 : (win[0] ? PP_pos_M   : PP_zero  ));

            // [FIXED] Map assignment securely into the flattened 1D array
            assign PP[(i+1)*PW-1 : i*PW] = ppf << (2 * i);

        end
    endgenerate

endmodule