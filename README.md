# 🚀 AMBA AHB-Lite Master Controller

A **parameterized AMBA AHB-Lite Master Controller** implemented in **SystemVerilog**, designed according to the **AMBA 3 AHB-Lite Specification**. The design provides a modular and synthesizable RTL implementation capable of performing single and burst transfers while supporting multiple transfer sizes and burst types.

The architecture is divided into independent modules, making the design easy to verify, maintain, and extend for FPGA and ASIC development.

---

# ✨ Features

- ✅ AMBA 3 AHB-Lite Compatible
- ✅ Modular RTL Design
- ✅ FSM-Based Transfer Controller
- ✅ Address Generator
- ✅ Burst Counter
- ✅ Address Register
- ✅ Read Buffer
- ✅ Write Buffer
- ✅ Timeout Detection
- ✅ CPU Interface
- ✅ Supports Single & Burst Transfers
- ✅ Supports Incrementing & Wrapping Bursts
- ✅ Parameterized Design
- ✅ Synthesizable RTL
- ✅ Verified using QuestaSim

---

# 🛠️ Supported Burst Types

| Burst Type | Description |
|------------|-------------|
| 📦 SINGLE | Single transfer |
| ➡️ INCR | Undefined length incrementing burst |
| 🔹 INCR4 | 4-beat incrementing burst |
| 🔸 INCR8 | 8-beat incrementing burst |
| 🔶 INCR16 | 16-beat incrementing burst |
| 🔄 WRAP4 | 4-beat wrapping burst |
| 🔄 WRAP8 | 8-beat wrapping burst |
| 🔄 WRAP16 | 16-beat wrapping burst |

---

# 📏 Supported Transfer Sizes

| HSIZE | Transfer Size |
|--------|---------------|
| 000 | 8-bit (Byte) |
| 001 | 16-bit (Halfword) |
| 010 | 32-bit (Word) |
| 011 | 64-bit (Doubleword) |
| 100 | 128-bit |

---

# 🏗️ Project Components

```text
📂 Project
│
├── FSM Controller
├── Address Generator
├── Burst Counter
├── Address Register
├── Write Buffer
├── Read Buffer
├── CPU Interface
├── Timeout Module
├── TOP Module
└── Testbench
```

---

# 📂 Project Structure

```text
.
├── rtl
│   ├── FSM_controller.sv
│   ├── Address_Generator.sv
│   ├── Burst_counter.sv
│   ├── Address_Register.sv
│   ├── Write_Buffer.sv
│   ├── Read_Buffer.sv
│   ├── CPU_Interface.sv
│   ├── Timeout.sv
│   └── AHB_Master_TOP.sv
│
├── tb
│   └── AHB_Master_tb.sv
│
└── README.md
```

---

# 🧠 Architecture

The AHB-Lite Master is divided into several independent modules.


![Architecture](photoes/Master_Architeture.drawio.png)


---

# ⚙️ FSM Controller

The **Finite State Machine (FSM)** controls the complete AHB-Lite transfer sequence by coordinating transaction initialization, burst execution, address updates, and transfer completion.

### ✨ Features

- 🚀 Starts new AHB transactions
- 📥 Loads burst counter and start address
- 🔄 Generates `NONSEQ` and `SEQ`
- 📍 Controls address progression
- 🔢 Controls burst counter
- ⏳ Waits for `HREADY`
- 🔁 Supports back-to-back transfers
- ⚠️ Handles timeout and slave error responses

### 📊 FSM State Diagram

> *(Add FSM image here)*

![FSM](photoes/Master_FSM.drawio.png)

---

# 📍 Address Generator

The Address Generator computes the next transfer address based on the current address, transfer size, and burst type.

### ✨ Features

- 📏 Supports all transfer sizes
- ➕ Automatic address increment
- 🔄 WRAP boundary calculation
- 📦 Supports SINGLE, INCR and WRAP bursts
- ⚡ Pure combinational logic
- ✅ Synthesizable RTL


# 🔢 Burst Counter

The Burst Counter tracks the remaining beats of each burst transfer.

### ✨ Features

- 📦 Supports SINGLE, INCR, WRAP bursts
- 🔢 Beat counting
- ✅ Transfer completion detection
- ⚡ Simple RTL implementation



# 🧪 Verification

The design is verified using functional simulation.

### Verified Features

- ✅ Single transfers
- ✅ Incrementing bursts
- ✅ Wrapping bursts
- ✅ Address generation
- ✅ Burst counting
- ✅ FSM transitions
- ✅ HREADY synchronization
- ✅ Error handling

---



# ⚙️ Simulation

Compile and simulate using **QuestaSim**.

The simulation verifies:

- 📄 FSM transitions
- 📄 Address generation
- 📄 Burst counting
- 📄 Bus transactions
- 📄 Waveforms

---

# 💻 Development Tools

- 🔹 SystemVerilog
- 🔹 QuestaSim
- 🔹 Visual Studio Code
- 🔹 Git & GitHub

---

# 📈 Future Improvements

- 🚀 Full AHB Master Verification Environment
- 🚀 UVM Testbench
- 🚀 Functional Coverage
- 🚀 Assertions (SVA)
- 🚀 DMA Controller Integration
- 🚀 AHB Arbiter Support
- 🚀 Multi-Master Support
- 🚀 AXI Bridge

---

# 👨‍💻 Authors

## Amr Soliman

**Communication & Electronics**

Passionate about:

- 💡 Digital Design
- ⚙️ RTL Design
- 🧩 ASIC Design
- 🚀 AMBA Protocols
- 🖥️ FPGA Design
- 🔬 Verification
- 🚀 VLSI Engineering

---

# ⭐ Support

If you like this project, give it a ⭐ on GitHub and feel free to contribute!
