module npu_accelerator (
    input  logic        clk,
    input  logic        rst_n,
    // AXI4 read channel from memory
    input  logic [31:0] axi_araddr,
    output logic [63:0] axi_rdata,
    input  logic        axi_rvalid,
    output logic        axi_rready,
    // Command Interface from Host
    input  logic        cmd_valid,
    input  logic [3:0]  cmd_op,    // 0=MATMUL, 1=DEQUANT
    input  logic [31:0] cmd_addr,
    input  logic [31:0] cmd_len,
    output logic        cmd_ready,
    // Control
    output logic        done,
    output logic [31:0] result
);
    // Internal signals
    logic [15:0] scale;
    logic [47:0] weights_q4;   // 12 nibbles per 64-bit beat (WIDTH=64)
    logic [15:0] dequant_weight;
    logic [15:0] input_act;
    logic [31:0] mac_result;
    logic        matmul_valid;

    assign cmd_ready   = 1'b1;   // accept commands whenever idle (simplified)
    assign matmul_valid = cmd_valid && (cmd_op == 4'b0000);
    assign input_act   = 16'd1;  // placeholder activation feed

    // AXI4 master (DMA skeleton): read channel active, write channel tied off
    // until the control FSM issues writes in a later revision.
    axi4_master axi (
        .clk(clk),
        .rst_n(rst_n),
        // Write address channel (unused)
        .awaddr(32'd0),
        .awburst(3'd0),
        .awcache(4'd0),
        .awid(4'd0),
        .awlen(8'd0),
        .awsize(3'd3),
        .awvalid(),
        .awready(1'b0),
        // Write data channel (unused)
        .wdata(64'd0),
        .wstrb(8'd0),
        .wvalid(),
        .wready(1'b0),
        // Write response channel (unused)
        .bresp(2'b00),
        .bvalid(1'b0),
        .bready(),
        // Read address channel
        .araddr(axi_araddr),
        .arburst(),
        .arcache(),
        .arid(),
        .arlen(),
        .arsize(),
        .arvalid(),
        .arready(1'b1),
        // Read data channel
        .rdata(axi_rdata),
        .rresp(2'b00),
        .rvalid(axi_rvalid),
        .rready(axi_rready)
    );

    // Block unpacker: parse weight beats fetched from memory
    block_unpacker #(
        .WIDTH(64)
    ) unpacker (
        .clk(clk),
        .rst_n(rst_n),
        .payload(axi_rdata),
        .scale(scale),
        .weights_q4(weights_q4)
    );

    // Dequantizer: convert Q4_0 to FP16 (w_i = d * (q_i - 8))
    gguf_q4_0_dequantizer dequant (
        .scale_fp16(scale),
        .quant_nibble(weights_q4[3:0]),
        .dequant_fp16(dequant_weight)
    );

    // PE pipeline: accumulate matrix-vector products
    pe_array_systolic pe (
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(matmul_valid),
        .weight(dequant_weight),
        .input_act(input_act),
        .accum_out(mac_result),
        .valid_out()
    );

    // Command decoder (combinational; sequential FSM is future work)
    always_comb begin
        case (cmd_op)
            4'b0000: begin // MATMUL operation
                result = mac_result;
                done   = matmul_valid;
            end
            4'b0001: begin // DEQUANT only
                result = {16'd0, dequant_weight};
                done   = cmd_valid;
            end
            default: begin
                result = 32'd0;
                done   = 1'b0;
            end
        endcase
    end

endmodule
