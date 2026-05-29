module CSR_Register_File #(
    parameter DATA_BUS_WIDTH  = 64
) (
    input                             clk, reset, csr_en,
    input  [1:0]                      funct3b21,   
    input  [11:0]                     csr_addr,
    input  [DATA_BUS_WIDTH-1 : 0]     csr_data, PC,
    output                            illegal_instruction,
    output reg                        pc_en,
    output reg [DATA_BUS_WIDTH-1 : 0] RD,
    output reg [DATA_BUS_WIDTH-1 : 0] PC_Next
);
    reg illeg_instr_r, illeg_instr_w;
    assign illegal_instruction = illeg_instr_r | illeg_instr_w; 

    reg [1:0] priv_q = 2'b00, priv_d = 2'b00; 

// ============================ CSR ADDRESS DEFINITIONS  ================================== //
                                           
    localparam MVENDORID = 12'hF11, MARCHID = 12'hF12, MIMPID = 12'hF13, MHARTID = 12'hF14; 
    localparam MSTATUS = 12'h300, MISA = 12'h301, MTVEC = 12'h305; 
    localparam MSCRATCH = 12'h340, MEPC = 12'h341, MCAUSE = 12'h342, MTVAL = 12'h343; 

// ========================= PHYSICAL REGISTER FLIP-FLOPS ================================= //

    // --- Machine Information Registers ---
    reg [DATA_BUS_WIDTH-1 : 0] mvendorid = 64'b0 ;  // JEDEC manufacturer ID
    reg [DATA_BUS_WIDTH-1 : 0] marchid = 64'b0 ;    // Open-source or commercial architecture ID
    reg [DATA_BUS_WIDTH-1 : 0] mimpid = 64'h0 ;     // Hardware implementation/version ID
    reg [DATA_BUS_WIDTH-1 : 0] mhartid = 64'b0 ;    // Hardware thread/core ID (0 for single core)

    // --- Machine Trap Setup ---
    reg [DATA_BUS_WIDTH-1 : 0] misa = 64'h8000_0000_0000_0100;       // Supported ISA and extensions bitmask (e.g., IMA)
    reg [DATA_BUS_WIDTH-1 : 0] mstatus_q, mstatus_d;    // Master status (interrupt enables, privilege states)
    reg [DATA_BUS_WIDTH-1 : 0] mtvec_q, mtvec_d;      // Base address of the Machine-mode trap handler

    // --- Machine Trap Handling ---
    reg [DATA_BUS_WIDTH-1 : 0] mscratch_q, mscratch_d;   // Scratch register for OS context switching (stack pointers)
    reg [DATA_BUS_WIDTH-1 : 0] mepc_q, mepc_d;       // Saves the PC of the instruction that caused the trap
    reg [DATA_BUS_WIDTH-1 : 0] mcause_q, mcause_d;     // Exception code indicating exactly why the trap happened
    reg [DATA_BUS_WIDTH-1 : 0] mtval_q, mtval_d;      // Extra trap context (e.g., faulting physical/virtual address)

// ==================================== Reading =========================================== //
    always @(*) begin
        illeg_instr_r = 1'b0; // Default to no illegal instruction
        if (priv_q < csr_addr[9:8]) begin
            illeg_instr_r = 1'b1;
            RD = 64'd0; 
        end
        else if (csr_en && funct3b21 != 2'b00) begin
            case (csr_addr)
                MVENDORID  : RD = mvendorid  ;
                MARCHID    : RD = marchid    ;
                MIMPID     : RD = mimpid     ;
                MHARTID    : RD = mhartid    ;
                MISA       : RD = misa       ;
                MSTATUS    : RD = mstatus_q  ;
                MTVEC      : RD = mtvec_q    ;
                MSCRATCH   : RD = mscratch_q ;
                MEPC       : RD = mepc_q     ;
                MCAUSE     : RD = mcause_q   ;
                MTVAL      : RD = mtval_q    ;
                default    : begin
                    illeg_instr_r = 1'b1;
                    RD = 64'd0;
                end
            endcase
        end else RD = 64'd0;
    end

// ==================================== Writing =========================================== //
    always @(*) begin
        illeg_instr_w = 1'b0;
        pc_en      = 1'b0;
        priv_d     = priv_q;
        mstatus_d  = mstatus_q;
        mtvec_d    = mtvec_q;
        mscratch_d = mscratch_q;
        mepc_d     = mepc_q;
        mcause_d   = mcause_q;
        mtval_d    = mtval_q;
        PC_Next    = PC;
        if (csr_en) begin
            case (funct3b21)
                2'b00: begin  // privilege instructions
                    case (csr_addr) 
                        12'h000: begin             // ecall
                            mepc_d               = PC;                       // Save current PC to mepc
                            mstatus_d[7]         = mstatus_q[3];             // MPIE <= MIE
                            mstatus_d[3]         = 1'b0;                     // MIE <= 0 
                            mstatus_d[12:11]     = priv_q;     // Previous Privilege <= current Mode
                            priv_d               = 2'b11;      // current privilege <= M-mode
                            PC_Next              = {mtvec_q[63:2], 2'b00};     // PCNext <= trap handler address
                            pc_en                = 1'b1;
                            case (priv_q)
                                2'b00: mcause_d  = 64'd8;      // Environment call from User mode
                                2'b01: mcause_d  = 64'd9;      // Environment call from Supervisor mode
                                2'b11: mcause_d  = 64'd11;     // Environment call from Machine mode 
                            endcase 
                        end
                        12'h001: begin             // ebreak                      
                            mepc_d               = PC;                       // Save current PC to mepc
                            mstatus_d[7]         = mstatus_q[3];             // MPIE <= MIE
                            mstatus_d[3]         = 1'b0;                     // MIE <= 0
                            mstatus_d[12:11]     = priv_q;     // Previous Privilege <= current Mode
                            priv_d               = 2'b11;      // current privilege <= M-mode
                            PC_Next              = {mtvec_q[63:2], 2'b00};     // PCNext <= trap handler address
                            pc_en                = 1'b1;
                            mcause_d             = 64'd3;                         
                        end
                        12'h302: begin             // mret
                            if (priv_q == 2'b11) begin
                                PC_Next              = mepc_q;  
                                pc_en                = 1'b1;
                                priv_d               = mstatus_q[12:11];              // next privilege level <= MPP
                                mstatus_d[12:11]     = 2'b00;           // MPP <= 0 (User mode)    
                                mstatus_d[3]         = mstatus_q[7];    // mpie <= MIE
                                mstatus_d[7]         = 1'b1; 
                            end
                            else illeg_instr_w = 1'b1;
                        end
                        default:  illeg_instr_w = 1'b1;
                    endcase            
                end

                2'b01: begin         //CSRRW
                    if (priv_q < csr_addr[9:8]) illeg_instr_w = 1'b1;
                    else begin
                        illeg_instr_w = 1'b0;
                        case (csr_addr)
                            MSTATUS    : mstatus_d  = csr_data ;
                            MTVEC      : mtvec_d    = csr_data ;
                            MSCRATCH   : mscratch_d = csr_data ;
                            MEPC       : mepc_d     = csr_data ;
                            MCAUSE     : mcause_d   = csr_data ;
                            MTVAL      : mtval_d    = csr_data ;
                            default    : illeg_instr_w = 1'b1;
                        endcase
                    end  
                end    

                2'b10: begin         //CSRRS
                    if (priv_q < csr_addr[9:8]) illeg_instr_w = 1'b1;
                    else if (csr_data == 0) begin
                        illeg_instr_w = 1'b0;
                    end
                    else begin
                        illeg_instr_w = 1'b0;
                        case (csr_addr)
                            MSTATUS  : mstatus_d  = mstatus_q  | csr_data ;
                            MTVEC    : mtvec_d    = mtvec_q    | csr_data ;
                            MSCRATCH : mscratch_d = mscratch_q | csr_data ;
                            MEPC     : mepc_d     = mepc_q     | csr_data ;
                            MCAUSE   : mcause_d   = mcause_q   | csr_data ;
                            MTVAL    : mtval_d    = mtval_q    | csr_data ;
                            default  : illeg_instr_w = 1'b1;
                        endcase
                    end
                end 

                2'b11:  begin        //CSRRC  
                    if (priv_q < csr_addr[9:8]) illeg_instr_w = 1'b1;
                    else if (csr_data == 0) begin
                        illeg_instr_w = 1'b0;
                    end
                    else begin
                        case (csr_addr)
                            MSTATUS  : mstatus_d  = mstatus_q  & ~csr_data ;
                            MTVEC    : mtvec_d    = mtvec_q    & ~csr_data ;
                            MSCRATCH : mscratch_d = mscratch_q & ~csr_data ;
                            MEPC     : mepc_d     = mepc_q     & ~csr_data ;
                            MCAUSE   : mcause_d   = mcause_q   & ~csr_data ;
                            MTVAL    : mtval_d    = mtval_q    & ~csr_data ;
                            default  : illeg_instr_w = 1'b1;
                        endcase
                    end
                end
            endcase
            if (illeg_instr_r || illeg_instr_w) begin
                mepc_d           = PC;
                mcause_d         = 64'd2;  // illegal instruction
                mtval_d          = 64'd0;  // or faulting instruction if you pass it in
                mstatus_d[7]     = mstatus_q[3];     // MPIE <= MIE
                mstatus_d[3]     = 1'b0;             // MIE <= 0
                mstatus_d[12:11] = priv_q;           // MPP <= current privilege
                priv_d           = 2'b11;            // enter M-mode
                PC_Next          = {mtvec_q[63:2], 2'b00};
                pc_en            = 1'b1;
            end
        end
    end

// =================================== FF Update ========================================== //
    always @(posedge clk or negedge reset) begin
        if(!reset) begin
            priv_q <= 2'b11;
            mstatus_q  <= 64'b0;
            mtvec_q    <= 64'b0; 
            mscratch_q <= 64'b0;
            mepc_q     <= 64'b0;
            mcause_q   <= 64'b0;
            mtval_q    <= 64'b0;
        end else begin
            priv_q <= priv_d;
            mstatus_q  <= mstatus_d;
            mtvec_q    <= mtvec_d;
            mscratch_q <= mscratch_d;
            mepc_q     <= mepc_d;
            mcause_q   <= mcause_d;
            mtval_q    <= mtval_d;
        end
    end

endmodule