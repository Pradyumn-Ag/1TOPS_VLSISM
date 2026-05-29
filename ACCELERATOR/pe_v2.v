`ifndef GLOBAL_SVH
`include "global.svh"
`endif
/* verilator lint_off UNUSEDSIGNAL */
module pe_v2(
    input clk,
    input rst_n,
    input signed [W-1:0] inA,
    input signed [W-1:0] inB,
    output signed [W-1:0] outA,
    output signed [W-1:0] outB,
    output signed [OUT_WIDTH-1:0] outS,

    output out_valid,
    output reg pass_valid_a, // data that is being passed is valid, propogates with outA
    output reg pass_valid_b, // propogates with out B
    input flush_acc,
    input in_valid_a,
    input in_valid_b
);

    // ================= STAGE 1: input registers =================
    reg signed [W-1:0] inA_reg, inB_reg;
    reg in_valid_r_a, in_valid_r_b;

    always @(posedge clk) begin
        if (!rst_n || flush_acc) begin
            inA_reg      <= {W{1'b0}};
            inB_reg      <= {W{1'b0}};
            in_valid_r_a <= 1'b0;
            in_valid_r_b <= 1'b0;
            pass_valid_a <= 1'b0;
            pass_valid_b <= 1'b0;
        end else begin
            inA_reg      <= inA;
            inB_reg      <= inB;
            in_valid_r_a <= in_valid_a;
            in_valid_r_b <= in_valid_b;
            pass_valid_a <= in_valid_a;
            pass_valid_b <= in_valid_b;
        end
    end

    assign outA = inA_reg;
    assign outB = inB_reg;

    wire zero_s1;
assign zero_s1 = ((inA_reg == 0) || (inB_reg == 0));
    // ================= STAGE 2: MULTIPLY (1 cycle) =================
    // Combinational Booth multiplier; result registered here.
    wire [2*W-1:0] product_comb;
    wire [W-1:0] mult_A;
    wire [W-1:0] mult_B;

    assign mult_A = zero_s1 ? 0 : inA_reg;
    assign mult_B = zero_s1 ? 0 : inB_reg;
    Booth_Multiplier mult (
        .M (mult_A),        // 8-bit signed
        .Q (mult_B),        // 8-bit signed
        .product (product_comb)   // 16-bit result
    );
    reg zero_s2;
    reg signed [2*W-1:0] product_reg;
    reg in_valid_r2_a, in_valid_r2_b;
    // outA_r / outB_r kept for structural symmetry (used by downstream if needed)
    reg signed [W-1:0] outA_r, outB_r;

    always @(posedge clk) begin
        if (!rst_n || flush_acc) begin
            product_reg  <= 0;
            outA_r       <= 0;
            outB_r       <= 0;
            in_valid_r2_a <= 1'b0;
            in_valid_r2_b <= 1'b0;
            zero_s2<= 1'b0;
        end else begin
            product_reg <= zero_s1 ? 0 : product_comb;   // register combinational result
            outA_r        <= inA_reg;
            outB_r        <= inB_reg;
            in_valid_r2_a <= in_valid_r_a;
            in_valid_r2_b <= in_valid_r_b;
            zero_s2 <=zero_s1;
        end
    end

    // ================= STAGE 3: MAC + COUNTER =================
    reg  signed [ACC_WIDTH-1:0] acc;
    reg [$clog2(N):0] counter;

    wire signed [ACC_WIDTH-1:0] product_ext;
    assign product_ext = {{(ACC_WIDTH-2*W){product_reg[2*W-1]}}, product_reg};

    wire signed [ACC_WIDTH-1:0] acc_next_i = acc + product_ext;

    // saturation limits
    localparam signed [ACC_WIDTH-1:0] OUT_MAX =
        {{(ACC_WIDTH-OUT_WIDTH+1){1'b0}}, {(OUT_WIDTH-1){1'b1}}};
    localparam signed [ACC_WIDTH-1:0] OUT_MIN =
        {{(ACC_WIDTH-OUT_WIDTH+1){1'b1}}, {(OUT_WIDTH-1){1'b0}}};

    wire overflow  = (acc_next_i > OUT_MAX);
    wire underflow = (acc_next_i < OUT_MIN);

    reg signed [ACC_WIDTH-1:0] acc_next;
    always @(*) begin
        if      (overflow)  acc_next = OUT_MAX;
        else if (underflow) acc_next = OUT_MIN;
        else                acc_next = acc_next_i;
    end

    wire last_mac = (counter == N-1) & (in_valid_r2_a & in_valid_r2_b);

    always @(posedge clk) begin
        if (!rst_n || flush_acc) begin
            acc     <= 0;
            counter <= 0;
        end else if (in_valid_r2_a & in_valid_r2_b) begin
           if(zero_s2) begin
              acc <= last_mac ? 0 : acc;
              counter <= (counter == N-1) ? 0 : counter + 1;
        end

            else begin
            acc <= last_mac ? 0 : acc_next;
            counter <= (counter == N-1) ? 0 : counter + 1;
    end
        end
    end

    // ================= OUTPUT =================
    assign out_valid = last_mac;
    assign outS      = acc_next[OUT_WIDTH-1:0];

endmodule
/* verilator lint_on UNUSEDSIGNAL */
