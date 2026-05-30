`timescale 1ns / 1ps
/* verilator lint_off UNUSEDSIGNAL */

// Fully compliant RISC-V M-Extension Combinational Multiplier
// Parameterized for scalable operand widths (Default: W = 64)
module Booth_Multiplier #(
    parameter W = 64                          // Operand width (e.g., 64 for RV64)
)(
    input  wire [W-1:0] M,                    // Multiplicand (rs1)
    input  wire [W-1:0] Q,                    // Multiplier   (rs2)
    input  wire [2:0]   funct3,               // Instruction funct3
    input  wire         is_word,              // 1 if MULW instruction
    output wire [W-1:0] Mul_Result            // Final formatted W-bit result
);

    // ------------------------------------------------------------------
    // Core Sizing
    // Radix-4 Booth requires an even width. We add 2 padding bits to 
    // safely handle zero-extension for unsigned * unsigned operations.
    // ------------------------------------------------------------------
    localparam CORE_W = W + 2;                // 66 for W=64
    localparam HALF_W = W / 2;                // 32 for W=64

    // ------------------------------------------------------------------
    // Step 1: Handle MULW (Word operations)
    // MULW treats the lower HALF_W bits as signed values.
    // ------------------------------------------------------------------
    wire [W-1:0] M_eff = is_word ? { {(W-HALF_W){M[HALF_W-1]}}, M[HALF_W-1:0] } : M;
    wire [W-1:0] Q_eff = is_word ? { {(W-HALF_W){Q[HALF_W-1]}}, Q[HALF_W-1:0] } : Q;

    // ------------------------------------------------------------------
    // Step 2: Determine Sign vs Zero Extension based on funct3
    // 000 = MUL    (signed * signed)
    // 001 = MULH   (signed * signed)
    // 010 = MULHSU (signed * unsigned) -> M is signed, Q is unsigned
    // 011 = MULHU  (unsigned * unsigned)
    // ------------------------------------------------------------------
    wire M_is_signed = (funct3 != 3'b011);                   
    wire Q_is_signed = (funct3 == 3'b000 || funct3 == 3'b001); 

    // Extract the padding bit (Sign bit if signed, 0 if unsigned)
    wire M_pad_bit = M_is_signed & M_eff[W-1];
    wire Q_pad_bit = Q_is_signed & Q_eff[W-1];

    // Extend operands to CORE_W bits (e.g., 66 bits)
    wire [CORE_W-1:0] M_ext = { {2{M_pad_bit}}, M_eff };
    wire [CORE_W-1:0] Q_ext = { {2{Q_pad_bit}}, Q_eff };

    // ------------------------------------------------------------------
    // Step 3: Instantiate the Core Hardware
    // ------------------------------------------------------------------
    localparam NUM_PP  = CORE_W / 2;          // 33 for W=64
    localparam PW      = 2 * CORE_W;          // 132 for W=64
    localparam PP_FLAT = NUM_PP * PW;         // 4356 for W=64

    wire [PP_FLAT-1:0] PP_flat;
    wire [PW-1:0]      product_full;

    Booth_Encoder #(
        .W (CORE_W)
    ) u_booth_enc (
        .M  (M_ext),
        .Q  (Q_ext),
        .PP (PP_flat)
    );

    Wallace_Tree #(
        .W (CORE_W)
    ) u_wallace_tree (
        .PP      (PP_flat),
        .product (product_full)
    );

    // ------------------------------------------------------------------
    // Step 4: Format Final Output based on Instruction
    // ------------------------------------------------------------------
    wire [W-1:0] lower_half = product_full[W-1:0];
    wire [W-1:0] upper_half = product_full[2*W-1:W];

    assign Mul_Result = is_word            ? { {(W-HALF_W){lower_half[HALF_W-1]}}, lower_half[HALF_W-1:0] } : 
                        (funct3 == 3'b000) ? lower_half :                             
                                             upper_half;                              

endmodule
/* verilator lint_on UNUSEDSIGNAL */