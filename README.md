# AMBA AHB-Lite Master IP & Verification Environment 🚀

![SystemVerilog](https://img.shields.io/badge/Language-SystemVerilog-blue.svg)
![Protocol](https://img.shields.io/badge/Protocol-AMBA_AHB--Lite-orange.svg)
![Verification](https://img.shields.io/badge/Verification-Directed_Testing-brightgreen.svg)
![Status](https://img.shields.io/badge/Status-Verified_&_Linted-success.svg)

## 📌 Overview
This repository contains the RTL design and a comprehensive verification environment for an **AMBA 3 AHB-Lite Master IP**. The core is a synthesizable SystemVerilog module designed to act as a high-performance, low-latency communication bridge initiating read and write transactions between a host processor and downstream peripherals.

The design supports zero-wait state pipelining, advanced burst operations, and robust error recovery, making it highly suitable for modern SoC integrations.

## ✨ Key Features
* **Protocol Compliance:** Fully conforms to the AMBA 3 AHB-Lite specification.
* **Burst Operations:** Supports `SINGLE`, `INCR4`, and `WRAP4` transfers.
* **Zero-Latency Pipelining:** Back-to-Back (B2B) transactions with perfect overlapping of Address and Data phases.
* **Stall Handling:** Dynamic wait-state injection handling via the `HREADY` signal without data loss.
* **Fault Tolerance:** Instant error detection (`HRESP`), burst abortion, and safe FSM state recovery.
* **Parametrized:** Configurable data width (Default: 32-bit).

---

## 🏗️ Hardware Architecture & Design

### Block Diagram
*(The architecture revolves around a centralized FSM, Address Generator, Burst Counter, and pipelined Read/Write Data Buffers.)*

<p align="center">
  <img src="photoes\Master_Architeture.drawio.png" alt="AHB Master Block Diagram" width="700"/>
</p>

### Master Finite State Machine (FSM)
The control logic is governed by a robust 3-state FSM (`IDLE`, `TRANSFER`, `BUSY`), ensuring clean transitions during standard bursts, pipelined requests, and error exceptions.

<p align="center">
  <img src="photoes\Master_FSM.drawio.png" alt="FSM Diagram" width="500"/>
</p>

---

## 🧪 Verification Environment
A deterministic, block-level SystemVerilog testbench was developed to rigorously verify the Master IP against protocol corner cases. A simplistic behavioral Peripheral Memory Model is utilized to act as the downstream slave target.

### Test Suites Implemented:
* `Single_Write` / `Single_Read`: Verifies basic transactions and address decoding.
* `INC4_Write` / `INCR4_Read`: Verifies burst counter logic and address increments.
* `B2B_Write_Read`: Verifies zero-idle phase overlapping.
* `B2B_Write_Write_Wait`: Verifies Master's ability to hold active address and data phases perfectly stable during a 2-cycle forced stall.
* `INCR4_Error_Test`: Injects a mid-burst error to verify transaction abortion and `CPU_Error` flag assertion.

---

## 📊 Simulation & Waveforms

### 1. Back-to-Back Transfers with Wait States
Demonstrates the Master FSM successfully freezing its internal pipeline when the Slave asserts wait states (`P_READY = 0`). The data phase (`1122_3344`) and subsequent address phase are held completely stable until the bus is released.

<p align="center">
  <img src="photoes\Master_WaveForm\backtoback_write&read_with_wait 2 cycle.png" alt="Wait States Waveform" width="800"/>
</p>

### 2. Burst Error Injection & Recovery
Shows the system's response to an injected `P_ERROR` mid-burst. The Master instantly aborts the remaining beats, cancels pending memory commits, alerts the CPU, and safely returns to `IDLE`.

<p align="center">
  <img src="photoes\Master_WaveForm\incr4 with error.png" alt="Error Recovery Waveform" width="800"/>
</p>

### 3. INCR4 Zero-Latency Burst
Illustrates seamless pipelining. The address for Beat *N* is successfully driven onto the bus concurrently with the data for Beat *N-1* with no wasted idle cycles.

<p align="center">
  <img src="photoes\Master_WaveForm\INCR4_read&write.png" alt="INCR4 Waveform" width="800"/>
</p>

---

## 🛠️ EDA Tooling & Sign-off
* **Simulation:** Verified using industry-standard simulators (Waveforms captured via Verdi/FSDB).
* **Static Analysis:** Processed through **Synopsys SpyGlass** for rigorous structural Linting and initial Clock Domain Crossing (CDC) abstract generation (`cdc_abstract`), adhering to STARC guidelines.

<p align="center">
  <img src="photoes\Master_WaveForm\spyglass.png" alt="SpyGlass CDC Analysis" width="800"/>
</p>

---

## 👨‍💻 Author
**Amr Soliman** *ASIC/FPGA Design & Verification* [LinkedIn Profile](https://www.linkedin.com/in/amr-soliman19) | [Email](mailto:amrsoliman916@gmail.com)
