
# Q4_0 Accelerator on FPGA

## Quantization Parameters

- Format: Q4_0
- Scale factor: 16-bit FP16
- Weight count per block: 32
- Mathematical model: $w_i = d \times (q_i - 8)$

## Key Modules Implemented

1. **AXI4 Master / DMA** - Memory fetch unit for weight blocks and activations
2. **Block Unpacker** - Parses 128-bit bus words into scale factors and 4-bit nibbles
3. **Dequantization Unit** - Converts packed quantized weights to FP16 representation
4. **PE Array / Systolic Engine** - Performs GEMV operations with MAC pipeline
5. **KV Cache Manager** - Manages key-value context during autoregressive generation

## Performance Estimate

- Throughput: TBD (FPGA prototype measurement)
- LUT utilization: TBD (INT8 vs FP16 implementation)
- Per-layer GEMV dimensions: 2048 x 2048
- Approximate parameter count: 1.24B weights
- Attention: 32 heads x 64 head_dim over 16 layers

