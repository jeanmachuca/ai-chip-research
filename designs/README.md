# Hardware Designs Directory

This directory will contain:

- **FPGA/ASIC gate-level designs** (`.v`, `.sv`)
- **Block diagrams** (`.dot`, `.png`, `.svg`)
- **Memory architecture schematics**
- **Power distribution schematics**
- **Testbench files** (`.sv`, `.v`)

## Contents

- `systolic_array/` - Systolic PE array designs
- `axi_interconnect/` - AXI4 bus interface designs
- `memory_controller/` - DDR/SRAM controller for weight streaming
- `kv_cache/` - Key-value cache management for transformer inference

## Status

Currently under development. See CI/CD workflow for integration tests.