+incdir+./RTL_Master
+incdir+./RTL_Slave
+incdir+./RTL_Top_Module

// ---------------------------
// RTL Master Files
// ---------------------------
./RTL_Master/Address_Generator.sv
./RTL_Master/Address_Register.sv
./RTL_Master/Burst_Counter.sv
./RTL_Master/Capture_Register.sv
./RTL_Master/FSM_controller.sv
./RTL_Master/Time_Out.sv
./RTL_Master/Top_Master.sv
./RTL_Master/write_Data_Register.sv

// ---------------------------
// RTL Slave Files
// ---------------------------
./RTL_Slave/AHB_Slave.sv
./RTL_Slave/Error_Response.sv

// ---------------------------
// RTL Top Module
// ---------------------------
./RTL_Top_Module/Top_AHB.sv
./RTL_Top_Module/reset_synchronizer.sv

// ---------------------------
// Testbench Files
// ---------------------------
./TestBench_Top/Master_Slave_tb.sv