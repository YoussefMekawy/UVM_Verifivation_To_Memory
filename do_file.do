vlib work
vlog -sv *.sv +cover -covercells
vsim -onfinish stop -displaymsgmode both -voptargs=+acc work.top_tb -cover
coverage save memory_cov.ucdb -onexit
run -all
coverage report -details