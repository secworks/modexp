#===================================================================
#
# Makefile
# --------
# Makefile for building the modular exponentiation submodules, core
# and top simulations.
#
#
# Author: Joachim Strombergson
# Copyright (c) 2014, Secworks Sweden AB
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or
# without modification, are permitted provided that the following
# conditions are met:
#
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in
#    the documentation and/or other materials provided with the
#    distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
# FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
# COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
# INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
# BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
# STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
# ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
#===================================================================

# Tools.
CC = iverilog
CCFLAGS = -Wall
LINT = verilator
LINTFLAGS = --lint-only -Wall

# Sources.
COMMON_SRC = ../src/rtl/adder32.v ../src/rtl/shl32.v ../src/rtl/shr32.v ../src/rtl/blockmem1r1w.v ../src/rtl/blockmem2r1w.v

RESIDUE_TB = ../src/tb/tb_residue.v
RESIDUE_SRC = ../src/rtl/residue.v

MONTPROD_TB = ../src/tb/tb_montprod.v
MONTPROD_SRC = ../src/rtl/montprod.v

TOP_SRC=../src/rtl/modexp.v $(MONTPROD_SRC) $(RESIDUE_SRC) $(COMMON_SRC)
TOP_TB=../src/tb/tb_modexp.v


# Rules.
all: top.sim montprod.sim residue.sim


top.sim: $(TOP_TB) $(TOP_SRC)
	$(CC) $(CCFLAGS) -o top.sim $(TOP_TB) $(TOP_SRC)


montprod.sim: $(MONTPROD_TB) $(MONTPROD_SRC) $(COMMON_SRC)
	$(CC) $(CCFLAGS) -o montprod.sim $(MONTPROD_TB) $(MONTPROD_SRC) $(COMMON_SRC)


residue.sim: $(RESIDUE_TB) $(RESIDUE_SRC) $(COMMON_SRC)
	$(CC) $(CCFLAGS) -o residue.sim $(RESIDUE_TB) $(RESIDUE_SRC) $(COMMON_SRC)


sim-top: top.sim
	./top.sim


sim-montprod: montprod.sim
	./montprod.sim


sim-residue: residue.sim
	./residue.sim


lint:
	@echo "Linting of montprod:"
	$(LINT) $(LINTFLAGS) --top-module montprod $(MONTPROD_SRC) $(COMMON_SRC)
	@echo ""

	@echo "Linting of residue:"
	$(LINT) $(LINTFLAGS) --top-module residue $(RESIDUE_SRC) $(COMMON_SRC)
	@echo ""

	@echo "Linting of modexp:"
	$(LINT) $(LINTFLAGS) --top-module modexp $(TOP_SRC)
	@echo ""


clean:
	rm -f top.sim
	rm -f montprod.sim
	rm -f residue.sim


help:
	@echo "Build system for simulation of modular exponentation core"
	@echo ""
	@echo "Supported targets:"
	@echo "------------------"
	@echo "all:          Build all simulation targets."
	@echo "lint:         Lint all modules and hierarchies."
	@echo "top.sim:      Build top level simulation target."
	@echo "montprod.sim: Build Montgomery product simulation target."
	@echo "residue.sim:  Build Residue calculation simulation target."
	@echo "sim-top:      Run top level simulation."
	@echo "sim-montprod: Run montprod simulation."
	@echo "sim-residue:  Run residue simulation."
	@echo "clean:        Delete all built files."

#===================================================================
# EOF Makefile
#===================================================================
