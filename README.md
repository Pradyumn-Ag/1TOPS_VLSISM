# 1TOPS_VLSISM

## Overview

This repository contains the RTL implementation of a pipelined RISC-V processor developed as part of the 1TOPS VLSI System Design competition. The processor integrates multiple architectural enhancements including pipelining, branch prediction, CSR support, multiplication/division extensions, and atomic operations.

The design focuses on building a scalable SoC-ready compute subsystem that can be integrated with hardware accelerators for high-performance applications such as real-time image recognition.

---

## Features

* 5-stage Pipelined RISC-V Processor
* Hazard Detection and Forwarding Logic
* Branch Prediction Unit
* CSR (Control and Status Register) Support
* Multiplication / Division Extensions
* Atomic Memory Operation (AMO) Support
* Instruction and Data Memory Modules
* Modular RTL Architecture
* Verilog-Based Implementation

---

## Architecture

The processor consists of the following pipeline stages:

1. Instruction Fetch (IF)
2. Instruction Decode (ID)
3. Execute (EX)
4. Memory Access (MEM)
5. Write Back (WB)

Additional architectural components:

* Control Unit
* ALU Decoder
* Register File
* Hazard Unit
* Branch Predictor
* Reservation Registers
* M Extension Unit
* CSR Register File

---

## Repository Structure

```text
├── PIPELINING.v                # Top level pipeline integration
├── CONTROL_UNIT.v             # Main control logic
├── ALU.v                      # Arithmetic Logic Unit
├── REGISTER_FILE.v            # Register file implementation
├── HAZARD_UNIT.v              # Hazard detection logic
├── CSR_Register_File.v        # CSR support
├── MULTIPLIER_UNIT.v          # Multiplication logic
├── DIVIDER_UNIT.v             # Division logic
├── AMO_ALU.v                  # Atomic operation unit
├── twob_predictor.v           # Branch predictor
├── DATA_MEMORY.v              # Data memory
├── INSTRUCTION_MEMORY.v       # Instruction memory
└── ...
```

---

## Supported Functionalities

* Integer Arithmetic Operations
* Logical Operations
* Branch Instructions
* Load / Store Operations
* CSR Instructions
* Multiply / Divide Operations
* Pipeline Hazard Resolution
* Branch Prediction

---

## Tools Used

* Verilog HDL
* ModelSim
* Vivado
* GTKWave

---

## Running Simulations

Compile RTL:

```bash
iverilog *.v -o processor.out
```

Run simulation:

```bash
vvp processor.out
```

View waveforms:

```bash
gtkwave waveform.vcd
```

---

## Applications

* SoC Development
* Processor Design Research
* Hardware Accelerator Integration
* Computer Architecture Learning
* FPGA Prototyping

---

## Future Work

* Cache Integration
* Full RV64 Support
* AXI Interconnect
* Accelerator Integration
* ASIC Implementation

---

## Contributors

Developed as part of the 1TOPS VLSI System Design competition project.

## License

This project is intended for educational and research purposes.
