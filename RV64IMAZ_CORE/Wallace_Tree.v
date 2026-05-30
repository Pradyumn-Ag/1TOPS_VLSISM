`timescale 1ns / 1ps
/* verilator lint_off UNUSEDSIGNAL */

module Wallace_Tree #(
    parameter W = 64                          // operand width
)(
    input  wire [(W/2)*(2*W)-1:0] PP,         // [FIXED] Flattened 1D array
    output wire [2*W-1:0]         product
);

    localparam NUM_PP = W / 2;  // 32
    localparam PW     = 2 * W;  //128

    localparam N0 = NUM_PP;
    localparam N1 = (N0/3)*2 + (N0%3);
    localparam N2 = (N1/3)*2 + (N1%3);
    localparam N3 = (N2/3)*2 + (N2%3);
    localparam N4 = (N3/3)*2 + (N3%3);
    localparam N5 = (N4/3)*2 + (N4%3);
    localparam N6 = (N5/3)*2 + (N5%3);
    localparam N7 = (N6/3)*2 + (N6%3);
    localparam N8 = (N7/3)*2 + (N7%3);

    wire [PW-1:0] L0 [0:NUM_PP-1];
    wire [PW-1:0] L1 [0:NUM_PP-1];
    wire [PW-1:0] L2 [0:NUM_PP-1];
    wire [PW-1:0] L3 [0:NUM_PP-1];
    wire [PW-1:0] L4 [0:NUM_PP-1];
    wire [PW-1:0] L5 [0:NUM_PP-1];
    wire [PW-1:0] L6 [0:NUM_PP-1];
    wire [PW-1:0] L7 [0:NUM_PP-1];
    wire [PW-1:0] L8 [0:NUM_PP-1];

    genvar p;
    generate
        for (p = 0; p < NUM_PP; p = p + 1) begin : load_pp
            // [FIXED] Part-select slice from the flat 1D bus
            assign L0[p] = PP[(p+1)*PW-1 : p*PW];
        end
    endgenerate

    genvar i;
    generate
        // ---- Level 0 -> 1 ----
        for (i = 0; i < N0/3; i = i + 1) begin : csa_l0
            wire [PW-1:0] ps, pc;
            CSA #(.N(PW)) u_csa (
                .A   (L0[3*i]),
                .B_in(L0[3*i+1]),
                .D   (L0[3*i+2]),
                .PS  (ps),
                .PC  (pc)
            );
            assign L1[2*i]   = ps;
            assign L1[2*i+1] = {pc[PW-2:0], 1'b0};
        end
        for (i = 0; i < N0%3; i = i + 1) begin : pass_l0
            assign L1[(N0/3)*2 + i] = L0[(N0/3)*3 + i];
        end

        // ---- Level 1 -> 2 ----
        for (i = 0; i < N1/3; i = i + 1) begin : csa_l1
            wire [PW-1:0] ps, pc;
            CSA #(.N(PW)) u_csa (
                .A   (L1[3*i]),
                .B_in(L1[3*i+1]),
                .D   (L1[3*i+2]),
                .PS  (ps),
                .PC  (pc)
            );
            assign L2[2*i]   = ps;
            assign L2[2*i+1] = {pc[PW-2:0], 1'b0};
        end
        for (i = 0; i < N1%3; i = i + 1) begin : pass_l1
            assign L2[(N1/3)*2 + i] = L1[(N1/3)*3 + i];
        end

        // ---- Level 2 -> 3 ----
        for (i = 0; i < N2/3; i = i + 1) begin : csa_l2
            wire [PW-1:0] ps, pc;
            CSA #(.N(PW)) u_csa (
                .A   (L2[3*i]),
                .B_in(L2[3*i+1]),
                .D   (L2[3*i+2]),
                .PS  (ps),
                .PC  (pc)
            );
            assign L3[2*i]   = ps;
            assign L3[2*i+1] = {pc[PW-2:0], 1'b0};
        end
        for (i = 0; i < N2%3; i = i + 1) begin : pass_l2
            assign L3[(N2/3)*2 + i] = L2[(N2/3)*3 + i];
        end

        // ---- Level 3 -> 4 ----
        for (i = 0; i < N3/3; i = i + 1) begin : csa_l3
            wire [PW-1:0] ps, pc;
            CSA #(.N(PW)) u_csa (
                .A   (L3[3*i]),
                .B_in(L3[3*i+1]),
                .D   (L3[3*i+2]),
                .PS  (ps),
                .PC  (pc)
            );
            assign L4[2*i]   = ps;
            assign L4[2*i+1] = {pc[PW-2:0], 1'b0};
        end
        for (i = 0; i < N3%3; i = i + 1) begin : pass_l3
            assign L4[(N3/3)*2 + i] = L3[(N3/3)*3 + i];
        end

        // ---- Level 4 -> 5 ----
        for (i = 0; i < N4/3; i = i + 1) begin : csa_l4
            wire [PW-1:0] ps, pc;
            CSA #(.N(PW)) u_csa (
                .A   (L4[3*i]),
                .B_in(L4[3*i+1]),
                .D   (L4[3*i+2]),
                .PS  (ps),
                .PC  (pc)
            );
            assign L5[2*i]   = ps;
            assign L5[2*i+1] = {pc[PW-2:0], 1'b0};
        end
        for (i = 0; i < N4%3; i = i + 1) begin : pass_l4
            assign L5[(N4/3)*2 + i] = L4[(N4/3)*3 + i];
        end

        // ---- Level 5 -> 6 ----
        for (i = 0; i < N5/3; i = i + 1) begin : csa_l5
            wire [PW-1:0] ps, pc;
            CSA #(.N(PW)) u_csa (
                .A   (L5[3*i]),
                .B_in(L5[3*i+1]),
                .D   (L5[3*i+2]),
                .PS  (ps),
                .PC  (pc)
            );
            assign L6[2*i]   = ps;
            assign L6[2*i+1] = {pc[PW-2:0], 1'b0};
        end
        for (i = 0; i < N5%3; i = i + 1) begin : pass_l5
            assign L6[(N5/3)*2 + i] = L5[(N5/3)*3 + i];
        end

        // ---- Level 6 -> 7 ----
        for (i = 0; i < N6/3; i = i + 1) begin : csa_l6
            wire [PW-1:0] ps, pc;
            CSA #(.N(PW)) u_csa (
                .A   (L6[3*i]),
                .B_in(L6[3*i+1]),
                .D   (L6[3*i+2]),
                .PS  (ps),
                .PC  (pc)
            );
            assign L7[2*i]   = ps;
            assign L7[2*i+1] = {pc[PW-2:0], 1'b0};
        end
        for (i = 0; i < N6%3; i = i + 1) begin : pass_l6
            assign L7[(N6/3)*2 + i] = L6[(N6/3)*3 + i];
        end

        // ---- Level 7 -> 8 ----
        for (i = 0; i < N7/3; i = i + 1) begin : csa_l7
            wire [PW-1:0] ps, pc;
            CSA #(.N(PW)) u_csa (
                .A   (L7[3*i]),
                .B_in(L7[3*i+1]),
                .D   (L7[3*i+2]),
                .PS  (ps),
                .PC  (pc)
            );
            assign L8[2*i]   = ps;
            assign L8[2*i+1] = {pc[PW-2:0], 1'b0};
        end
        for (i = 0; i < N7%3; i = i + 1) begin : pass_l7
            assign L8[(N7/3)*2 + i] = L7[(N7/3)*3 + i];
        end
    endgenerate

    // ---- Final stage into KSA ----
    wire unused_cout_final;
    KSA #(.N(PW)) ksa_final (
        .a   (L8[0]),
        .b   (L8[1]),
        .cin (1'b0),
        .sum (product),
        .cout(unused_cout_final)
    );

endmodule
/* verilator lint_on UNUSEDSIGNAL */