`ifndef GLOBAL_SVH
`include "global.svh"
`endif

module mme (
    input logic clk,
    input logic rst_n,

    // ibuf_a read interface
    output logic [$clog2(BUF_SIZE)-1:0] ibuf_a_raddr,
    input logic [B*W-1:0] ibuf_a_din,
    output logic ibuf_a_ren,
    input logic ibuf_a_rvalid,

    // ibuf_b read interface
    output logic [$clog2(BUF_SIZE)-1:0] ibuf_b_raddr,
    input logic [B*W-1:0] ibuf_b_din,
    output logic ibuf_b_ren,
    input logic ibuf_b_rvalid,

    // obuf write interface
    output logic [N*OUT_WIDTH-1:0] outputbus_flat,
    output logic [N-1:0] valid_row,

    // trials
    input logic flush_acc,
    input logic feed_done
);

    // FIFO controller
    logic [W-1:0] fifo_out_a [0:FIF_LINES-1];
    logic [FIF_LINES-1:0] fifo_out_valid_a;

    logic [W-1:0] fifo_out_b [0:FIF_LINES-1];
    logic [FIF_LINES-1:0] fifo_out_valid_b;
    logic [N*W-1:0] fifo_A_flat;
    logic [N*W-1:0] fifo_B_flat;


    fifo_controller fifo_controller_inst (
        .clk(clk),
        .rst_n(rst_n),

        // buffer interface A
        .buf_addr_a(ibuf_a_raddr),
        .buf_req_a(ibuf_a_ren),
        .buffer_in_a(ibuf_a_din),
        .buffer_in_valid_a(ibuf_a_rvalid),

        // buffer interface B
        .buf_addr_b(ibuf_b_raddr),
        .buf_req_b(ibuf_b_ren),
        .buffer_in_b(ibuf_b_din),
        .buffer_in_valid_b(ibuf_b_rvalid),

        // output to PE array
        .fifo_out_a(fifo_out_a),
        .fifo_out_valid_a(fifo_out_valid_a),
        .fifo_out_b(fifo_out_b),
        .fifo_out_valid_b(fifo_out_valid_b),
        .feed_done(feed_done)
    );
  genvar k;
    generate
        for (k = 0; k < N; k = k+1) begin : FLATTEN_FIFO
            assign fifo_A_flat[k*W +: W] = fifo_out_a[k];
            assign fifo_B_flat[k*W +: W] = fifo_out_b[k];
        end
    endgenerate
    pe_array pe_array_inst (
        .clk(clk),
        .rst_n(rst_n),

        .flush_acc(flush_acc),

        .in_valid_a(fifo_out_valid_a),
        .in_valid_b(fifo_out_valid_b),

        .fifo_A_flat(fifo_A_flat),
        .fifo_B_flat(fifo_B_flat),

        .outputbus_flat(outputbus_flat),
        .valid_row(valid_row)
    );    
endmodule
