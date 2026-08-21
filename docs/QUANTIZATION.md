# Handling GGUF Quantization Formats in Hardware

GGUF models store weights in **block-quantized formats** (e.g., `Q4_0`, `Q4_K`, `Q8_0`) to conserve bandwidth.

## Example: Understanding `Q4_0` Format

A `Q4_0` block stores 32 weights using:

1. **Scale Factor ($d$):** A 16-bit floating-point value (`FP16`).
2. **Quantized Weights ($q_i$):** 32 4-bit values (nibbles), stored unsigned and interpreted as signed via the $-8$ offset.

The actual mathematical value of weight $i$ is calculated as:

$$w_i = d \times (q_i - 8)$$

### Implemented Dequantizer

The implemented module is [`src/verilog/gguf_q4_0_dequantizer.sv`](../src/verilog/gguf_q4_0_dequantizer.sv). It decodes the FP16 scale, multiplies by the signed offset $q_i - 8$, and re-normalizes to FP16 (truncating rounding; subnormal scales flush to zero).

### Reference Integration Pattern

The following pattern shows how the dequantizer composes with integer-to-FP16 conversion and an FP16 multiplier when those units are available as IP. These submodules are integration points, not part of this repository:

```systemverilog
module gguf_q4_0_dequantizer (
    input  logic [15:0]  scale_fp16,  // Scale factor (d)
    input  logic [3:0]   quant_nibble, // 4-bit packed weight (q_i)
    output logic [15:0]  dequant_fp16  // Unpacked weight
);
    // 1. Subtract offset to get signed nibble (-8 to +7)
    logic signed [4:0] signed_weight;
    assign signed_weight = $signed({1'b0, quant_nibble}) - 5'sd8;

    // 2. Convert signed nibble to FP16 representation
    logic [15:0] weight_fp16;
    int_to_fp16 u_conv (
        .in_int(signed_weight),
        .out_fp16(weight_fp16)
    );

    // 3. Multiply scale by weight: d * (q_i - 8)
    fp16_multiplier u_mul (
        .a(scale_fp16),
        .b(weight_fp16),
        .result(dequant_fp16)
    );

endmodule
```