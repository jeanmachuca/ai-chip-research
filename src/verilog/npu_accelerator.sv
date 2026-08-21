module npu_accelerator (
    input  logic        clk,
    input  logic        rst_n,
    // AXI4 Interface for DMA
    input  logic [31:0] axi_awaddr,
    input  logic [31:0] axi_araddr,
    output logic [63:0] axi_rdata,
    input  logic        axi_rvalid,
    output logic        axi_rready,
    output logic [63:0] axi_bresp,
    input  logic        axi_bvalid,
    output logic        axi_bready,
    // Command Interface from Host
    input  logic        cmd_valid,
    input  logic [3:0]  cmd_op,    // 0=MATMUL, 1=DEQUANT, etc.
    input  logic [31:0] cmd_addr,
    input  logic [31:0] cmd_len,
    output logic        cmd_ready,
    // Control
    output logic        done,
    output logic [31:0] result
);
    // Internal signals
    logic [15:0] scale;
    logic [63:0] weights_q4;
    logic [15:0] dequant_weight;
    logic [15:0] input_act;
    logic [31:0] mac_result;
    logic        matmul_valid;
    
    // DMA / AXI interfaces
    axi4_master axi (
        .clk(clk),
        .rst_n(rst_n),
        // Write address
        .awaddr(axi_awaddr),
        .awvalid(), // simplified
        // Read address  
        .araddr(axi_araddr),
        .arvalid(),
        // Read data
        .rdata(axi_rdata),
        .rvalid(axi_rvalid),
        .rready(axi_rready),
        // Write response
        .bresp(axi_bresp),
        .bvalid(),
        .bready()
    );
    
    // Block unpacker: parse weight blocks from memory
    block_unpacker unpacker (
        .payload(axi_rdata),
        .scale(scale),
        .weights_q4(weights_q4)
    );
    
    // Dequantizer: convert Q4_0 to FP16
    gguf_q4_0_dequantizer dequant (
        .scale_fp16(scale),
        .quant_nibble(weights_q4[3:0]),
        .dequant_fp16(dequant_weight)
    );
    
    // PE array: perform matrix multiplication
    pe_array_systolic pe (
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(matmul_valid),
        .weight(dequant_weight),
        .input_act(input_act),
        .accum_out(mac_result),
        .valid_out()
    );
    
    // State machine and command decoder
    always_comb begin
        case (cmd_op)
            4'b0000: begin // MATMUL operation
                // Fetch weights, dequantize, compute MAC
                result <= mac_result;
                done <= matmul_valid;
            end
            4'b0001: begin // DEQUANT only
                result <= dequant_weight;
                done <= 1'b1;
            end
            default: begin
                result <= 32'd0;
                done <= 1'b0;
            end
        endcase
    end
endmodule