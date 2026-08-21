# Architectural Strategy: Software vs. Hardware Boundary

## Philosophy

Attempting to parse binary GGUF headers directly in SystemVerilog hardware is inefficient and overly complex. Instead, divide the system cleanly:

### Software Host / Firmware (ARM / RISC-V / Python)

1. Reads the GGUF file header
2. Extracts hyper-parameters (layer count, head count, quantization type)
3. Allocates external memory (DRAM)
4. Writes raw quantized weight arrays directly into RAM
5. Dispatches high-level instructions to hardware (e.g., `MATMUL Layer 1, Weights@0x8000, Input@0x1000`)

### SystemVerilog Hardware Accelerator

1. Fetches quantized weights from memory
2. Decodes/dequantizes the format
3. Executes low-precision matrix-vector products (MatVec/GEMV)
4. Applies activation functions
5. Streams results back to RAM

## Design Goal

Build a **Matrix Multiplication & Attention Accelerator** that interfaces with software/DMA to parse and execute GGUF-encoded operations, rather than trying to implement the full GGUF parser in hardware.