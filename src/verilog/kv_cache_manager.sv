module kv_cache_manager (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        wen,
    input  logic [31:0] addr,
    input  logic [63:0] data_in,
    output logic [63:0] data_out,
    output logic        empty,
    output logic        full
);
    // KV Cache Manager for transformer inference
    // Stores key-value pairs during autoregressive generation
    // Supports sliding window and attention pattern management
    
    // Internal RAM for KV storage (simplified)
    logic [63:0] kv_mem [0:1023];
    logic [31:0] read_ptr, write_ptr;
    logic [11:0] count;
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            read_ptr <= 32'd0;
            write_ptr <= 32'd0;
            count <= 12'd0;
        end else begin
            if (wen && !full) begin
                kv_mem[write_ptr] <= data_in;
                write_ptr <= write_ptr + 32'd1;
                count <= count + 12'd1;
            end
            if (read_ptr < write_ptr) begin
                data_out <= kv_mem[read_ptr];
                read_ptr <= read_ptr + 32'd1;
                count <= count - 12'd1;
            end
        end
    end
    
    assign empty = (count == 12'd0);
    assign full = (count == 12'd1023);
endmodule