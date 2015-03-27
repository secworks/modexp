# Makefile for building and running motprod simulation.

TB_SRC = tb_motprod.v
RTL_SRC = ../rtl/montprod.v ../rtl/adder32.v ../rtl/shr32.v ../rtl/blockmem.v


test: testmotprod.sim
	./testmotprod.sim

testmotprod.sim: $(TB_SRC) $(RTL_SRC)
	iverilog -Wall -o testmotprod.sim $(TB_SRC) $(RTL_SRC)

clean:
	rm testmotprod.sim
