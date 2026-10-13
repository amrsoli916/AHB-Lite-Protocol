+incdir+./RTL_Master
+incdir+./CPU_Master_Interface
+incdir+./Pipeline_MIPS
+incdir+./RTL_Slave
+incdir+./UART_IP
+incdir+./UART_Slave_Interface
+incdir+./Top_Integration_System
+incdir+./Async_FIFO
+incdir+./Top_Integration_System_tb
+incdir+./Memory_Slave

./RTL_Master/Address_Generator.sv
./RTL_Master/Address_Register.sv
./RTL_Master/Burst_Counter.sv
./RTL_Master/Capture_Register.sv
./RTL_Master/FSM_controller.sv
./RTL_Master/Time_Out.sv
./RTL_Master/Top_Master.sv
./RTL_Master/write_Data_Register.sv


./CPU_Master_Interface/Top_CPU_With_Master.sv

./Pipeline_MIPS/Adder.v
./Pipeline_MIPS/ALU.v
./Pipeline_MIPS/Control_Unit.v
./Pipeline_MIPS/equal.v
./Pipeline_MIPS/EX_MEM_Reg.v
./Pipeline_MIPS/Float_Reg.v
./Pipeline_MIPS/fpu_alignment.v
./Pipeline_MIPS/fpu_alu.v
./Pipeline_MIPS/fpu_normalizer.v
./Pipeline_MIPS/fpu_packer.v
./Pipeline_MIPS/fpu_top.v
./Pipeline_MIPS/fpu_unpacker.v
./Pipeline_MIPS/Hazard_Unit.v
./Pipeline_MIPS/ID_EX_Reg.v
./Pipeline_MIPS/IF_ID_Reg.v
./Pipeline_MIPS/instruction_memory.v
./Pipeline_MIPS/MEM_WB_Reg.v
./Pipeline_MIPS/Mux2to1.v
./Pipeline_MIPS/Mux3to1.v
./Pipeline_MIPS/Pc_reg.v
./Pipeline_MIPS/Register_File.v
./Pipeline_MIPS/Shift_Branch.v
./Pipeline_MIPS/sign_ext.v
./Pipeline_MIPS/TOP_Pip_MIPS.v

./RTL_Slave/slave_Peripheral_interface.sv
./RTL_Slave/slave_register.sv
./RTL_Slave/slave_response_handler.sv
./RTL_Slave/slave_transfer_decoder.sv
./RTL_Slave/slave_wrapper.sv

./UART_IP/impl_top.v
./UART_IP/uart_rx.v
./UART_IP/UART_TOP.sv
./UART_IP/uart_tx.v

./UART_Slave_Interface/Double_Flop_Sync.sv
./UART_Slave_Interface/UART_SLAVE_INTERFACE.sv
./UART_Slave_Interface/dff_with_rstn.sv
./UART_Slave_Interface/rstn_sync.sv
./UART_Slave_Interface/lvl_to_pulse.sv

./Top_Integration_System/reset_synchronizer.sv
./Top_Integration_System/Top_Integration.sv
./Top_Integration_System/AHB_Decoder.sv
./Top_Integration_System/MUX.sv

./Async_FIFO/binary_to_gray.v
./Async_FIFO/fifo_top.v
./Async_FIFO/Memory.v
./Async_FIFO/read_handler.v
./Async_FIFO/syncronizer.v
./Async_FIFO/write_handler.v

./Top_Integration_System_tb/Integration_tb.sv

./Memory_Slave/dff_with_set.sv
./Memory_Slave/Register_file.sv
./Memory_Slave/rst_sync.sv
./Memory_Slave/Slave-syn_mem.sv
