# ==========================================
# Makefile for Synopsys VCS & Verdi (Multi-Directory)
# ==========================================

# 1. Variables (Update paths to match your folder names exactly)
# The wildcard function will now grab every .sv file inside these specific folders
RTL_FILES = $(wildcard RTL_Master/*.sv) \
            $(wildcard RTL_Slave/*.sv) \
            $(wildcard RTL_Top_Module/*.sv) \
            $(wildcard TestBench_Top/*.sv)

VCS_FLAGS = -sverilog -debug_access+all -kdb -ignore initializer_driver_checks

# Default target: Do everything (Compile, Run, Open Verdi)
all: compile run verdi

# 2. Compile the SystemVerilog files
compile:
	vcs $(VCS_FLAGS) $(RTL_FILES)

# 3. Run the simulation to generate the FSDB waveform file
run:
	./simv

# 4. Open Verdi with the generated waveform
verdi:
	verdi -ssf waves.fsdb &

# 5. Clean up all generated files (keeps your root folder clean)
clean:
	rm -rf simv simv.daidir csrc ucli.key *.fsdb novas* verdiLog vdCovLog *~