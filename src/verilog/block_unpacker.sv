module block_unpacker #(
    // Width of the incoming bus word (e.g., AXI4 read data width).
    parameter int WIDTH = 64,
    // Whole nibbles that fit after the 16-bit scale.
    parameter int NUM_WEIGHTS = (WIDTH - 16) / 4
) (
    input  logic                  clk,
    input  logic                  rst_n,
    input  logic [WIDTH-1:0]      payload,
    output logic [15:0]           scale,
    output logic [4*NUM_WEIGHTS-1:0] weights_q4
);
    // GGUF Q4_0 block layout (18 bytes per block):
    //   bytes 0-1  : FP16 scale factor d
    //   bytes 2-17 : 32 x 4-bit values (q_i, interpreted as q_i - 8)
    //
    // A single bus word of WIDTH bits carries the 16-bit scale followed by
    // NUM_WEIGHTS whole nibbles. For WIDTH = 64 that is 12 weights; a full
    // 32-weight block is streamed across multiple beats (beat sequencing
    // handled by the control FSM).

    // Scale factor occupies the first 16 bits of the word
    assign scale = payload[15:0];

    // Weight i occupies the 4 bits starting at bit offset 16 + i*4
    generate
        genvar i;
        for (i = 0; i < NUM_WEIGHTS; i = i + 1) begin : g_unpack
            assign weights_q4[i*4 +: 4] = payload[16 + i*4 +: 4];
        end
    endgenerate
endmodule
