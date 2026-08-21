module block_unpacker (
    input  logic        clk,
    input  logic        rst_n,
    input  logic [127:0] payload,
    output logic [15:0] scale,
    output logic [63:0] weights_q4
);
    // Q4_0 format: 16 bytes scale factor (FP16) + 32 × 4-bit weights packed into 16 bytes
    // Total 128-bit payload: [scale_fp16 (16 bits) | reserved | 32 nibbles]
    
    // Extract scale factor from bits [15:0]
    assign scale = payload[15:0];
    
    // Extract quantized nibbles - each weight is 4 bits, 32 weights = 128 bits / 4 = 32 weights
    // But we have 16 bytes = 128 bits of weight data after scale
    // Actually Q4_0: 2 bytes scale + 16 bytes weights = 32 weights × 4 bits = 64 bits packed into 16 bytes
    // Let me reconsider: typical Q4_0 block is 2 bytes scale + 16 bytes packed weights = 32 weights
    
    // For 128-bit bus: first 16 bits = scale, remaining 112 bits = 28 × 4-bit weights
    // Actually let me use the standard: scale at [15:0], then weights packed
    
    generate
        genvar i;
        for (i = 0; i < 32; i = i + 1) begin
            // Weight i is at bit position [i*4 + 15 : i*4 + 12] (after scale at bits 15:0)
            // But need to account for packing in bytes
            assign weights_q4[i*4 +: 4] = payload[i*4 + 19 : i*4 + 16];
        end
    endgenerate
endmodule