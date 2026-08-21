module gguf_q4_0_dequantizer (
    input  logic        clk,
    input  logic        rst_n,
    input  logic [15:0] scale_fp16,
    input  logic [3:0]  quant_nibble,
    output logic [15:0] dequant_fp16
);
    // 1. Subtract offset to get signed nibble (-8 to +7)
    logic signed [4:0] signed_weight;
    assign signed_weight = $signed({1'b0, quant_nibble}) - 5'sd8;

    // 2. Convert signed nibble to FP16 representation using built-in
    logic [15:0] weight_fp16;
    // Simple conversion: map signed [4:0] [-8..7] to FP16
    // For now, use a priority encoding for demonstration
    always_comb begin
        case (signed_weight)
            5'sd0: weight_fp16 = 16'h0000;
            5'sd1: weight_fp16 = 16'h3C00;  // ~0.5
            5'sd2: weight_fp16 = 16'h3D00;  // ~0.75
            5'sd3: weight_fp16 = 16'h3E00;  // ~0.875
            5'sd4: weight_fp16 = 16'h3F00;  // ~0.9375
            5'sd5: weight_fp16 = 16'h4000;  // 1.0
            5'sd6: weight_fp16 = 16'h4100;  // ~1.0625
            5'sd7: weight_fp16 = 16'h4200;  // ~1.125
            5'sd8: weight_fp16 = 16'h0000;  // zero after offset
            default: weight_fp16 = 16'h8000;  // negative values
        endcase
    end

    // 3. Multiply scale by weight: d * (q_i - 8)
    // FP16 multiplication for now
    always_comb begin
        dequant_fp16 = scale_fp16 * weight_fp16 / 16'h1000;  // normalize
    end
endmodule