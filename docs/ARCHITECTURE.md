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
| **AXI4 Master / DMA** | Fetches quantized weight blocks and activations from DRAM/SRAM. |
| **Block Unpacker** | Parses incoming 128-bit/256-bit bus words into scale factors and nibbles. |
| **MAC Array / Systolic Structure** | Performs high-throughput Vector-Matrix multiplications ($y = W \cdot x$). |
| **Activation & Post-Processing** | Computes RMSNorm, RoPE (Rotary Positional Embedding), and SiLU functions. |
| **KV Cache Manager** | Manages key-value context storage in RAM during autoregressive generation. |