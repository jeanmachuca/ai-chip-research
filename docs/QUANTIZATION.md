# Handling GGUF Quantization Formats in Hardware

GGUF models store weights in **block-quantized formats** (e.g., `Q4_0`, `Q4_K`, `Q8_0`) to conserve bandwidth.

## Example: Understanding `Q4_0` Format

A `Q4_0` block stores 32 weights using:

1. **Scale Factor ($d$):** A 16-bit floating-point value (`FP16`).
2. **Quantized Weights ($q_i$):** 32 4-bit signed integers (nibbles) packed into 16 bytes.

The actual mathematical value of weight $i$ is calculated as:

$$w_i = d \times (q_i - 8)$$

### Dequantizer Implementation Pattern

Your SystemVerilog hardware must contain a dequantizer module that unpacks raw bytes into numeric values before feeder logic sends them to Multiply-Accumulate (MAC) units.

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