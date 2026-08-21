# System Architecture Diagram

```
 +-----------------------------------------------------------------------+
 |                            Host CPU / SPI                             |
 |  1. Parses GGUF file (headers, metadata, scale factors, block weights)  |
 |  2. Writes raw blocks to External DDR / SRAM                          |
 |  3. Sends Command Descriptor to Accelerator Command FIFO              |
 +----------------------------------+------------------------------------+
                                    |
                                    v AXI4 Bus
 +-----------------------------------------------------------------------+
 |                     SystemVerilog AI Accelerator                      |
 |                                                                       |
 |   +-----------------+     +-----------------+     +---------------+   |
 |   | Instruction     | --> | DMA Controller  | --> | Weight Buffer |   |
 |   | Decoder / FSM   |     | (AXI Master)    |     | (SRAM / FIFO) |   |
 |   +-----------------+     +-----------------+     +-------+-------+   |
 |                                                           |           |
 |                                                           v           |
 |   +---------------------------------------------------------------+   |
 |   |        Dequantization Unit (e.g. Q4_0 -> FP16 / INT16)        |   |
 |   +-------------------------------+-------------------------------+   |
 |                                   |                                   |
 |                                   v                                   |
 |   +---------------------------------------------------------------+   |
 |   | Processing Element (PE) Array / Systolic Engine (MAC Pipeline)  |   |
 |   +-------------------------------+-------------------------------+   |
 |                                   |                                   |
 |                                   v                                   |
 |   +---------------------------------------------------------------+   |
 |   |      Accumulators -> Quantization / Activation (RMSNorm/RoPE)   |   |
 |   +---------------------------------------------------------------+   |
 +-----------------------------------------------------------------------+
```

## Module Reference

| Module | Function |
| --- | --- |
| **AXI4 Master / DMA** | Fetches quantized weight blocks and activations from DRAM/SRAM. *(Skeleton: port definitions complete, protocol FSM pending.)* |
| **Block Unpacker** | Parses incoming bus words (parameterized width) into scale factors and nibbles. |
| **MAC Array / Systolic Structure** | Performs high-throughput Vector-Matrix multiplications ($y = W \cdot x$). *(Single PE implemented; array scaling planned.)* |
| **Activation & Post-Processing** | Computes RMSNorm, RoPE (Rotary Positional Embedding), and SiLU functions. *(Planned — not yet implemented.)* |
| **KV Cache Manager** | Manages key-value context storage in RAM during autoregressive generation. |

Implemented modules live in [`src/verilog/`](../src/verilog/); `npu_accelerator` is the top-level integration module.