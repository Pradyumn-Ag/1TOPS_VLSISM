# 1TOPS_VLSISM

## Overview

This repository contains the RTL implementation of a feature-rich pipelined RISC-V processor developed as part of the 1TOPS VLSI System Design Competition.

The project combines a 5-stage pipelined RISC-V CPU with advanced architectural features such as branch prediction, CSR support, multiplication/division extensions, atomic memory operations, and AI accelerator integration.

The objective is to create a scalable SoC-ready compute platform capable of serving as a foundation for FPGA prototyping, computer architecture research, and hardware acceleration of AI workloads.

---

## Features

### Processor Features

* 5-Stage Pipelined RISC-V Processor
* Hazard Detection and Forwarding Logic
* Branch Prediction Unit
* CSR (Control and Status Register) Support
* Multiplication Extension (M Extension)
* Division Unit
* Atomic Memory Operations (AMO)
* Instruction and Data Memory Modules
* Modular RTL Architecture
* Verilog-Based Implementation

### AI Accelerator Features

* Systolic Array Based Processing Architecture
* Matrix Multiplication Engine (MME)
* Processing Element (PE) Array
* FIFO-Based Data Streaming
* Scalable Accelerator Design
* Parallel Multiply-Accumulate (MAC) Operations
* Hardware-Friendly AI Compute Pipeline
* FPGA Prototyping Support

---

## System Architecture

### Processor Pipeline Stages

The processor follows a standard 5-stage pipeline architecture:

1. Instruction Fetch (IF)
2. Instruction Decode (ID)
3. Execute (EX)
4. Memory Access (MEM)
5. Write Back (WB)

### Additional Architectural Components

* Control Unit
* ALU Decoder
* Register File
* Hazard Detection Unit
* Branch Predictor
* Reservation Registers
* CSR Register File
* Multiplier Unit
* Divider Unit
* AMO Execution Unit

### AI Accelerator Subsystem

The AI accelerator subsystem consists of:

* Processing Element (PE) Array
* Matrix Multiplication Engine (MME)
* FIFO Controllers
* Input/Output Buffers
* Streaming Dataflow Infrastructure

These modules are designed to accelerate matrix-based computations commonly used in machine learning, DSP, and image-processing applications.

---

## Repository Structure

```text
├── PIPELINING.v                 # Top-level processor integration
│
├── CONTROL_UNIT.v              # Main control logic
├── MAIN_DECODER.v              # Instruction decoder
├── ALU_DECODER.v               # ALU control decoder
│
├── ALU.v                       # Arithmetic Logic Unit
├── ADDER.v                     # Adder unit
├── AMO_ALU.v                   # Atomic Memory Operations
│
├── REGISTER_FILE.v             # Register file
├── CSR_Register_File.v         # CSR implementation
│
├── MULTIPLIER_UNIT.v           # Multiplier Unit
├── Booth_Multiplier.v          # Booth multiplier
├── Booth_Encoder.v             # Booth encoder
├── Wallace_Tree.v             # Wallace tree reduction
├── CSA.v                       # Carry-save adder
├── KSA.v                       # Kogge-Stone adder
├── FA.v                        # Full adder
│
├── DIVIDER_UNIT.v              # Divider unit
│
├── HAZARD_UNIT.v               # Hazard detection
├── RESERVATION_REGISTER.v      # Reservation register
│
├── twob_predictor.v            # Two-bit branch predictor
├── twob_ctr.v                  # Predictor controller
│
├── INSTRUCTION_MEMORY.v        # Instruction memory
├── DATA_MEMORY.v               # Data memory
├── instr_rom_32bit.xci         # Vivado instruction ROM
├── instruction.coe             # Program initialization file
│
├── IF_ID_reg.v                 # Pipeline register
├── dff_rst.v                   # DFF with reset
├── dff_rst_en.v                # DFF with reset and enable
│
├── MUX_2x1.v                   # Multiplexer
├── MUX_3x1.v
├── MUX_4x1.v
├── MUX_5x1.v
│
├── EXTEND_UNIT.v              # Immediate extension
├── M_EXT_UNIT.v               # M-extension support
├── PC_1.v                     # Program counter
│
├── iladata.ila                # Vivado ILA configuration
│
├── pe_v2.v                    # Processing element
├── pe4x4.v                    # 4x4 PE array
├── pe_array.v                 # Scalable PE array
├── mme.sv                     # Matrix multiplication engine
│
├── fifo.sv                    # FIFO buffer
├── fifo_controller.sv         # FIFO control logic
├── buffer.sv                  # Data buffer
├── op_buffer.v                # Operand buffer
│
└── README.md
```

---

## Supported Instruction Functionality

### Base Integer Operations

* Arithmetic Instructions
* Logical Instructions
* Shift Operations
* Comparison Instructions

### Memory Operations

* Load Instructions
* Store Instructions

### Control Flow

* Conditional Branches
* Jumps
* Branch Prediction Support

### System Instructions

* CSR Read/Write Operations
* CSR Status Handling

### Extension Support

* Multiplication Instructions
* Division Instructions
* Atomic Memory Operations (AMO)

---

## AI Accelerator Modules

### Processing Element (PE)

The Processing Element forms the basic compute unit responsible for multiply-accumulate (MAC) operations.

Features:

* Parallel Computation
* Low-Latency MAC Operations
* Systolic Array Compatibility

### PE Array

The PE array combines multiple processing elements to perform large-scale matrix operations efficiently.

Features:

* Parallel Data Processing
* Scalable Architecture
* Efficient Resource Utilization

### Matrix Multiplication Engine (MME)

The MME is designed to accelerate matrix multiplication workloads.

Features:

* High Throughput
* Streaming Dataflow
* AI-Oriented Computation

### FIFO Infrastructure

FIFO and buffering modules provide efficient data movement between compute stages.

Features:

* Data Synchronization
* Streaming Support
* Pipeline Decoupling

---

## Accelerator Repository

A dedicated repository containing detailed documentation, architecture diagrams, implementation details, and accelerator development information is available at:

https://github.com/adityalg/AI_accelerator

---

## Tools Used

### Design

* Verilog HDL
* SystemVerilog

### Simulation

* ModelSim
* Vivado Simulator
* Icarus Verilog

### Verification & Debug

* GTKWave
* Vivado ILA

### FPGA Development

* Xilinx Vivado

---

## Running Simulations

### Compile RTL

```bash
iverilog *.v *.sv -o processor.out
```

### Run Simulation

```bash
vvp processor.out
```

### View Waveforms

```bash
gtkwave waveform.vcd
```

---

## FPGA Implementation Flow

1. Import RTL into Vivado.
2. Add instruction memory initialization file (`instruction.coe`).
3. Configure Block Memory Generator IP.
4. Synthesize the design.
5. Run implementation.
6. Generate bitstream.
7. Program FPGA.
8. Debug using Integrated Logic Analyzer (ILA).

---

## Applications

### Processor Applications

* Computer Architecture Research
* RISC-V Learning Platform
* FPGA-Based Processor Prototyping
* Embedded Systems Development

### Accelerator Applications

* Neural Network Inference
* Matrix Computation
* Image Processing
* Digital Signal Processing (DSP)
* Edge AI Systems
* Hardware Accelerator Research

### System-Level Applications

* SoC Development
* Processor + Accelerator Co-Design
* FPGA Compute Platforms
* Custom AI Hardware Exploration

---

## Future Work

### Processor Enhancements

* Cache Integration
* Full RV64 Support
* AXI Interconnect
* MMU Support
* Performance Optimization

### Accelerator Enhancements

* Larger Systolic Arrays
* Convolution Acceleration
* Quantized Inference Support
* On-Chip Memory Optimization
* Multi-Accelerator Integration

### SoC Integration

* Processor-Accelerator Interface
* Shared Memory Architecture
* DMA Engine Support
* Full FPGA SoC Deployment

---

## Contributors

Developed as part of the 1TOPS VLSI System Design Competition.

---

## License

This project is intended for educational, research, and learning purposes.
