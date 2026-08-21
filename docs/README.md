# AI Chip Research Documentation

This repository contains the research and SystemVerilog implementation of a hardware accelerator for GGUF-quantized large language model inference.

## Repository Structure

```
ai-chip-research/
├── docs/                  # Research documentation and architecture guides
├── designs/               # SystemVerilog source files and FPGA prototypes
├── src/                   # Verilog source code (axi4_master, pe_array, etc.)
├── scripts/               # Python pipelines for paper generation
├── papers/                # Generated LaTeX papers and reports
├── submissions/           # Zenodo/arxiv submission packages
└── tex/                   # LaTeX source files and bibliographies
```

## Key Research Areas

1. **GGUF Quantization Format Support**
   - Q4_0: 16-bit scale + 32×4-bit packed weights
   - Q4_K: Kronecker-factored quantization
   - Q8_0: 8-bit integer quantization

2. **Software/Hardware Boundary**
   - Host: GGUF file parsing, metadata extraction, DRAM allocation
   - Hardware: Dequantization, MAC array, systolic engine

3. **SystemVerilog Modules**
   - AXI4 Master/DMA interface
   - Block unpacker for packed nibbles
   - Q4_0 dequantizer (scale × (q_i − 8))
   - Systolic PE array for GEMV
   - KV cache manager for transformer inference

## Getting Started

### FPGA Prototyping (Phase 1)

1. Use the embedded ARM core on Zynq/Kria to parse GGUF files via C program
2. Stream raw blocks to SystemVerilog IP via AXI-Stream
3. Test with small quantized models (Llama-3.2-1B Q4_0 or Q8_0)

### Build and Run

```bash
# View documentation
cd /workspace/ai-chip-research
ls docs/

# Run paper pipeline
python3 scripts/generate_paper.py --model llama-3.2-1b-q4_0 --quant Q4_0 --arch FPGA

# Generated outputs will appear in papers/ directory
```

## References

- GGUF Format Specification: https://gguf.spec.
- NVDLA: NVIDIA Deep Learning Accelerator
- VTA: Versatile Tensor Accelerator (TVM)
- RoPE: Rotary Positional Embedding
- RMSNorm: Root Mean Square Layer Normalization