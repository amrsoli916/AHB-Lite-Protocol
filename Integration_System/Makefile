VCS = vcs -full64 -sverilog -debug_access+all -kdb

compile:
	$(VCS) -f filelist.f

run: compile
	./simv

verdi:
	verdi \
	-f filelist.f \
	-dbdir simv.daidir \
	-ssf CPU_AHB.fsdb \
	-ssr signal.ses &

clean:
	rm -rf simv simv.daidir csrc *.log *.key *.fsdb novas* ucli.key