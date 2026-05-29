`ifndef GLOBAL_SVH
`include "global.svh"
`endif

/* verilator lint_off UNUSEDSIGNAL */
/* verilator lint_off CMPCONST */
module fifo_controller (
    input logic clk,
    input logic rst_n,

    // buffer interface A
    output logic [$clog2(BUF_SIZE)-1:0] buf_addr_a, // which address to read next
    output logic buf_req_a,
    input logic [W*B-1:0] buffer_in_a,
    input logic buffer_in_valid_a,

    // buffer interface B
    output logic [$clog2(BUF_SIZE)-1:0] buf_addr_b,
    output logic buf_req_b,
    input logic [W*B-1:0] buffer_in_b,
    input logic buffer_in_valid_b,

    // output to PE array
    output logic [W-1:0] fifo_out_a[0:FIF_LINES-1],
    output logic [FIF_LINES-1:0] fifo_out_valid_a,
    output logic [W-1:0] fifo_out_b[0:FIF_LINES-1],
    output logic [FIF_LINES-1:0] fifo_out_valid_b,

    input logic feed_done
);

  //////////////////////////////////////////////////////////
  // FIFO connections  A
  //////////////////////////////////////////////////////////

  logic [W-1:0] fifo_din_a[0:N-1];
  logic [W-1:0] fifo_dout_a[0:N-1];

  logic [N-1:0] fifo_wen_a;
  logic [N-1:0] fifo_ren_a;
  logic [N-1:0] fifo_full_a;
  logic [N-1:0] fifo_empty_a;

  //////////////////////////////////////////////////////////
  // FIFO connections  B
  //////////////////////////////////////////////////////////

  logic [W-1:0] fifo_din_b[0:N-1];
  logic [W-1:0] fifo_dout_b[0:N-1];

  logic [N-1:0] fifo_wen_b;
  logic [N-1:0] fifo_ren_b;
  logic [N-1:0] fifo_full_b;
  logic [N-1:0] fifo_empty_b;


  //////////////////////////////////////////////////////////
  // FIFO instantiation  A
  //////////////////////////////////////////////////////////

  genvar j;

  generate
    for (j = 0; j < N; j++) begin : fifo_gen_a

      fifo #(
          .DEPTH(FIF_DEPTH)
      ) fifo_j (
          .clk(clk),
          .rst_n(rst_n),
          .data_in(fifo_din_a[j]),
          .w_en(fifo_wen_a[j]),
          .r_en(fifo_ren_a[j]),
          .data_out(fifo_dout_a[j]),
          .full(fifo_full_a[j]),
          .empty(fifo_empty_a[j])
      );

    end
  endgenerate

  //////////////////////////////////////////////////////////
  // FIFO instantiation  B
  //////////////////////////////////////////////////////////

  genvar l;

  generate
    for (l = 0; l < N; l++) begin : fifo_gen_b

      fifo #(
          .DEPTH(FIF_DEPTH)
      ) fifo_l (
          .clk(clk),
          .rst_n(rst_n),
          .data_in(fifo_din_b[l]),
          .w_en(fifo_wen_b[l]),
          .r_en(fifo_ren_b[l]),
          .data_out(fifo_dout_b[l]),
          .full(fifo_full_b[l]),
          .empty(fifo_empty_b[l])
      );

    end
  endgenerate


  //////////////////////////////////////////////////////////
  // Controller registers
  //////////////////////////////////////////////////////////

  logic [$clog2(BUF_SIZE)-1:0] addr_reg_a;
  logic [$clog2(BUF_SIZE)-1:0] addr_reg_b;

  logic [$clog2(N/B)-1:0] line_ctr; // tells which fifo pair to write
  logic [$clog2(N)-1:0] col_ctr;

  logic  [N-1:0] en_sig;
  logic [$clog2(N):0] en_ctr; // counts till N, enables fifo
  logic [$clog2(N):0] inter_ctr;
  logic [$clog2((N*N)/B):0] load_ctr;

  // logic feed_done;


  //////////////////////////////////////////////////////////
  // FSM states
  //////////////////////////////////////////////////////////

  typedef enum logic [1:0] {
    RESET,
    INTER,
    // FILL,
    FEED
  } state_t;

  state_t state, next_state;

  // next state combinational logic
  always_comb begin 
    next_state = RESET;
    case (state)
        RESET: next_state = INTER;
       INTER: next_state =(load_ctr == ((N*N)/(2*B)-1))? FEED: INTER;
        FEED: next_state = feed_done ? RESET : FEED;
        default :next_state = RESET;
    endcase
  end  

  // next state sequential logic
  always_ff @( posedge clk ) begin 
    if(!rst_n) begin
        state <= RESET;
        line_ctr <= '0;
        col_ctr  <= '0;
        addr_reg_a <= '0;
        addr_reg_b <= '0;
        en_ctr <= '0;
        inter_ctr <= '0;
        fifo_out_valid_a <= '0;
        fifo_out_valid_b <= '0;
        load_ctr <= 0;

    end else begin

        state <= next_state;
      if ((state == INTER || state == FEED) &&buffer_in_valid_a &&buffer_in_valid_b)begin

          if(line_ctr == $bits(line_ctr)'((N/B)-1))
             line_ctr <= '0;
           else
               line_ctr <= line_ctr + 1;
               end 
        if (line_ctr == $bits(line_ctr)'(N/B - 1)) col_ctr <= col_ctr + 1;
        if (state == INTER ||  state == FEED) addr_reg_a <= addr_reg_a + 1;
        if (state == INTER ||  state == FEED) addr_reg_b <= addr_reg_b + 1;
        if(state == INTER && buffer_in_valid_a &&buffer_in_valid_b) load_ctr <= load_ctr + 1;

        if (state == FEED) begin
            if (en_ctr <= $bits(en_ctr)'(N)) begin
                en_ctr <= en_ctr + 1;
            end else en_ctr <= en_ctr;
        end

        if (state == INTER) inter_ctr <= inter_ctr + 1;

        fifo_out_valid_a <= fifo_ren_a;
        fifo_out_valid_b <= fifo_ren_b;
    end
  end

  always_comb begin
      en_sig = '0;
      for (int k = 0; k <en_ctr; k++) begin
          
            en_sig[k] = 1'b1;
          
      end
  end

  // output comb logic
  always_comb begin

    //////////////////////////////////////////////////////////
    // default values
    //////////////////////////////////////////////////////////

    for (int i = 0; i < N; i++) begin
      fifo_din_a[i] = '0;
      fifo_din_b[i] = '0;
    end

    fifo_wen_a = '0;
    fifo_ren_a = '0;

    fifo_wen_b = '0;
    fifo_ren_b = '0;

    buf_addr_a = '0;
    buf_req_a  = '0;

    buf_addr_b = '0;
    buf_req_b  = '0;

    for (int i = 0; i < FIF_LINES; i++) begin
      fifo_out_a[i] = '0;
      fifo_out_b[i] = '0;
    end    

    //////////////////////////////////////////////////////////
    // FSM outputs
    //////////////////////////////////////////////////////////

    case (state)

      //////////////////////////////////////////////////////////
      RESET: begin
        // defaults already applied
        
      end

      INTER :begin
        for (int i = 0; i < B; i++) begin
          if (buffer_in_valid_a) begin
            fifo_din_a[line_ctr*B+i] = buffer_in_a[W*i+:W];
            fifo_wen_a[line_ctr*B+i] = 1'b1;
          end
          if (buffer_in_valid_b) begin
            fifo_din_b[line_ctr*B+i] = buffer_in_b[W*i+:W];
            fifo_wen_b[line_ctr*B+i] = 1'b1;
          end
        end

        buf_req_a = '1;
        buf_addr_a = addr_reg_a;

        buf_req_b = '1;
        buf_addr_b = addr_reg_b;
      end

      FEED: begin

        for (int i = 0; i < B; i++) begin
          if (buffer_in_valid_a) begin
            fifo_din_a[line_ctr*B+i] = buffer_in_a[W*i+:W];
            fifo_wen_a[line_ctr*B+i] = 1'b1;
          end
          if (buffer_in_valid_b) begin
            fifo_din_b[line_ctr*B+i] = buffer_in_b[W*i+:W];
            fifo_wen_b[line_ctr*B+i] = 1'b1;
          end
        end

        buf_req_a = '1;
        buf_addr_a = addr_reg_a;

        buf_req_b = '1;
        buf_addr_b = addr_reg_b;
        for (int i = 0; i < N; i++) begin
    fifo_ren_a[i] = en_sig[i] & ~fifo_empty_a[i];
    fifo_ren_b[i] = en_sig[i] & ~fifo_empty_b[i];
end

        for (int i = 0; i < FIF_LINES; i++) begin
          fifo_out_a[i] = fifo_dout_a[i];
          fifo_out_b[i] = fifo_dout_b[i];
        end

        // fifo_out_valid = '1;

      end
      default: begin
        
      end

    endcase

  end


endmodule
/* verilator lint_on UNUSEDSIGNAL */
/* verilator lint_on CMPCONST */
