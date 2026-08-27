VCS = vcs -full64 -sverilog -debug_access+all -kdb -ignore initializer_driver_checks

compile:
	$(VCS) -f filelist.f

run: compile
	./simv

verdi:
	verdi \
	-f filelist.f \
	-dbdir simv.daidir \
	-ssf waves.fsdb \
	-ssr signal.ses &

clean:
	rm -rf simv simv.daidir csrc *.log *.key *.fsdb novas* ucli.key