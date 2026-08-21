module axi4_master (
    input  logic        clk,
    input  logic        rst_n,
    // AXI4 Write Address Channel
    output logic [31:0] awaddr,
    output logic [2:0]  awburst,
    output logic [3:0]  awcache,
    output logic [3:0]  awid,
    output logic [7:0]  awlen,
    output logic [2:0]  awsize,
    output logic        awvalid,
    input  logic        awready,
    // AXI4 Write Data Channel
    output logic [63:0] wdata,
    output logic [7:0]  wstrb,
    output logic        wvalid,
    input  logic        wready,
    // AXI4 Write Response Channel
    input  logic [1:0]  bresp,
    input  logic        bvalid,
    output logic        bready,
    // AXI4 Read Address Channel
    output logic [31:0] araddr,
    output logic [2:0]  arburst,
    output logic [3:0] arcache,
    output logic [3:0]  arid,
    output logic [7:0]  arlen,
    output logic [2:0]  arsize,
    output logic        arvalid,
    input  logic        arready,
    // AXI4 Read Data Channel
    input  logic [63:0] rdata,
    input  logic [1:0]  rresp,
    input  logic        rvalid,
    output logic        rready
);
endmodule