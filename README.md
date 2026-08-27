# AMBA AHB-Lite Master/Slave IP & Pipelined MIPS Integration 🚀

![SystemVerilog](https://img.shields.io/badge/Language-SystemVerilog-blue.svg)
![Protocol](https://img.shields.io/badge/Protocol-AMBA_AHB--Lite-orange.svg)
![Verification](https://img.shields.io/badge/Verification-Directed_Testing-brightgreen.svg)
![Status](https://img.shields.io/badge/Status-Verified_&_Linted-success.svg)

## 📌 Overview
This repository contains the complete RTL design, verification environment, and SoC integration for an **AMBA 3 AHB-Lite Bus Architecture**, featuring a custom high-performance **AHB Master/Slave IP**, a 5-stage pipelined **MIPS Processor**, and a **UART Subsystem** operating across asynchronous clock domains.

---

## 🗂️ Repository Structure
* **`My_AHB/`** $\rightarrow$ Contains all AHB Design components, Master IP, Slave memory models, and standalone verification files.
* **`Integration_System/`** $\rightarrow$ Houses the top-level SoC integration combining the Pipelined MIPS Processor, AHB bus infrastructure, and UART peripheral working on an independent clock domain.
* **`photoes/`** $\rightarrow$ Contains architecture diagrams, FSM charts, and verification waveforms.

---

## ✨ Key Features & Architecture
* **Protocol Compliance:** Fully conforms to the AMBA 3 AHB-Lite specification.
* **Pipelined MIPS Core:** A custom 5-stage pipelined MIPS processor featuring data forwarding, hazard detection unit, and single-precision floating-point support (add.s, sub.s).
* **Asynchronous Clock Domain Integration:** Integrates peripherals like UART operating on an independent clock domain relative to the main AHB-Lite bus domain.
* **Zero-Latency Pipelining:** Back-to-Back (B2B) transactions with optimal overlapping of Address and Data phases via a dedicated Data Alignment Register wrapper.
* **Stall Handling:** Dynamic wait-state injection handling via the `HREADY` signal without data loss.

---

## 🏗️ Hardware Architecture & Design

### AHB Master Block Diagram
<p align="center">
  <img src="photoes/Master_Architeture.drawio.png" alt="AHB Master Block Diagram" width="700"/>
</p>

### Master Finite State Machine (FSM)
<p align="center">
  <img src="photoes/Master_FSM.drawio.png" alt="FSM Diagram" width="500"/>
</p>

---

## 📊 Simulation & Waveforms

### 1. Back-to-Back Transfers with Wait States
<p align="center">
  <img src="photoes/Master_WaveForm/backtoback_write&read_with_wait 2 cycle.png" alt="Wait States Waveform" width="800"/>
</p>

### 2. Burst Error Injection & Recovery
<p align="center">
  <img src="photoes/Master_WaveForm/incr4 with error.png" alt="Error Recovery Waveform" width="800"/>
</p>

### 3. INCR4 Zero-Latency Burst
<p align="center">
  <img src="photoes/Master_WaveForm/INCR4_read&write.png" alt="INCR4 Waveform" width="800"/>
</p>

---

## 🛠️ EDA Tooling & Sign-off
* **Simulation:** Verified using industry-standard simulators (Synopsys VCS / Verdi FSDB).
* **Static Analysis:** Processed through **Synopsys SpyGlass** for rigorous structural Linting and Clock Domain Crossing (CDC) verification.

<p align="center">
  <img src="photoes/Master_WaveForm/spyglass.png" alt="SpyGlass CDC Analysis" width="800"/>
</p>

---

## 👨‍💻 Author
**Amr Soliman** *ASIC/FPGA Design & Verification* [LinkedIn Profile](https://www.linkedin.com/in/amr-soliman19) | [Email](mailto:amrsoliman916@gmail.com)