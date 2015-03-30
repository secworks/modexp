# Makefile for building and running motprod simulation.

TB_SRC = tb_motprod.v
RTL_SRC = ../rtl/montprod.v ../rtl/adder32.v ../rtl/shr32.v ../rtl/blockmem1r1w.v


all: testmotprod.sim

testmotprod.sim: $(TB_SRC) $(RTL_SRC)
	iverilog -Wall -o testmotprod.sim $(TB_SRC) $(RTL_SRC)

lint:  $(RTL_SRC)
	verilator --lint-only $(RTL_SRC)

test: testmotprod.sim
	./testmotprod.sim

clean:
	rm testmotprod.sim
