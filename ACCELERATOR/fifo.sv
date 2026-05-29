`ifndef GLOBAL_SVH
`include "global.svh"
`endif
//  FIF_DEPTH = N = 16.  After loading exactly 16 elements,
//  tail wraps back to 0.  At that point head == 0 == tail,
//  so  head == tail  evaluates to 1 (empty = TRUE) even though
//  the FIFO is completely full.
//
//  In FEED state, fifo_ren[i] is gated by !fifo_empty[i].
//  With empty stuck at 1, no FIFO is ever read → outputs
//  stay zero forever.
//
//  Fix:  assign empty = (count == 0);   ← always correct
module fifo #(
    // parameter int W = 16,       // WORD SIZE
    parameter int DEPTH = 16
) (
    input logic clk,
    input logic rst_n,

    input logic [W-1:0] data_in,
    input logic w_en,
    input logic r_en,

    output logic [W-1:0] data_out,
    output logic full,
    output logic empty
);

  logic [W-1:0] mem [0:DEPTH-1] ;
  logic [$clog2(DEPTH)-1:0] head, tail;
  logic [$clog2(DEPTH):0] count;

  always_ff @( posedge clk ) begin 
    if(!rst_n) begin
        for(int i =0;i<DEPTH; i++)begin
            mem[i] <= '0;
        end
        head <= '0;
        tail <= '0;
        data_out <= '0;
        count <= '0;
    end else begin
        case ({w_en & ~full, r_en & ~empty})
            2'b10: count <= count + 1; // write only
            2'b01: count <= count - 1; // read only
            2'b11: count <= count;     // both → no change
            default: count <= count;
        endcase
        if(w_en & ~full)begin
             mem[tail] <= data_in;
            tail <= (tail == $bits(tail)'(DEPTH-1)) ? 0 : tail + 1;
            
        end
        if(r_en & ~empty) begin
            data_out <= mem[head];
            head <= (head == $bits(head)'(DEPTH-1)) ? 0 : head + 1;  // Convert DEPTH-1 into same width as head
            
        end
    end
  end
  
  assign full = (count == ($clog2(DEPTH + 1)'(DEPTH)));
  assign empty = (count==0);
    
endmodule
