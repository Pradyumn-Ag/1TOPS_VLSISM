`timescale 1ns / 1ps
/* verilator lint_off UNUSEDSIGNAL */

module KSA #(
    parameter N = 128                                 // bit-width (= 2*W), must be power of 2
)(
    input  wire [N-1:0] a, b,
    input  wire         cin,
    output wire [N-1:0] sum,
    output wire         cout
);
    // ---- Stage 0: bit-level G and P ----
    wire [N-1:0] G0 = a & b;                          // generate
    wire [N-1:0] P0 = a ^ b;                          // propagate

    wire [N-1:0] Gp;
    assign Gp[0]       = G0[0] | (P0[0] & cin);
    assign Gp[N-1:1]   = G0[N-1:1];

    // ---- Prefix stages ----
    localparam STAGES = $clog2(N);

    // [FIXED] Verilog-2001 explicit bounds
    wire [N-1:0] G_st [0:STAGES];
    wire [N-1:0] P_st [0:STAGES];

    assign G_st[0] = Gp;
    assign P_st[0] = P0;

    genvar s, k;
    generate
        for (s = 0; s < STAGES; s = s + 1) begin : prefix_stage
            
            // [FIXED] Removed the SV "int" keyword
            localparam STRIDE = (1 << s); 

            for (k = 0; k < N; k = k + 1) begin : prefix_bit
                if (k < STRIDE) begin
                    assign G_st[s+1][k] = G_st[s][k];
                    assign P_st[s+1][k] = P_st[s][k];
                end else begin
                    assign G_st[s+1][k] = G_st[s][k] | (P_st[s][k] & G_st[s][k-STRIDE]);
                    assign P_st[s+1][k] = P_st[s][k] & P_st[s][k-STRIDE];
                end
            end
        end
    endgenerate

    // ---- Post-processing ----
    wire [N-1:0] carry;
    assign carry[0]     = cin;
    assign carry[N-1:1] = G_st[STAGES][N-2:0];

    assign sum  = P0 ^ carry;
    assign cout = G_st[STAGES][N-1];

endmodule
/* verilator lint_on UNUSEDSIGNAL */