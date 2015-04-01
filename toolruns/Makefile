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

# tools
CC = iverilog
CCFLAGS = -wall
LINT = verilator
LINTFLAGS = --lint-only -Wall

# sources
MONTPROD_TB = ../src/tb/tb_motprod.v
MONTPROD_SRC = ../src/rtl/montprod.v ../src/rtl/adder32.v ../src/rtl/shr32.v ../src/rtl/blockmem1r1w.v

TOP_SRC=../src/rtl/modexp.v $(MONTPROD_SRC)
TOP_TB=../src/rtl/tb_modexp.v


# rules
all: top.sim montprod.sim


top.sim: $(TOP_SRC)
	$(CC) -o top.sim $(TOP_SRC)


montprod.sim: $(MONTPROD_TB_SRC) $(MONTPROD_SRC)
	iverilog -Wall -o montprod.sim $(MONTPROD_TB_SRC) $(MONTPROD_SRC)


sim-top: top.sim
	./top.sim


sim-montprod: montprod.sim
	./montprod.sim


lint:
	@echo "Linting of montprod:"
	$(LINT) $(LINTFLAGS) $(MONTPROD_SRC)
	@echo ""

	@echo "Linting of modexp:"
	$(LINT) $(LINTFLAGS) $(TOP_SRC)
	@echo ""


clean:
	rm -f top.sim
	rm -f montprod.sim


help:
	@echo "Build system for simulation of modular exponentation core"
	@echo ""
	@echo "Supported targets:"
	@echo "------------------"
	@echo "all:          Build all simulation targets."
	@echo "lint:         Lint all modules and hierarchies."
	@echo "top.sim:      Build top level simulation target."
	@echo "sim-top:      Run top level simulation."
	@echo "montprod.sim: Build montprod simulation target."
	@echo "sim-montprod: Run montprod simulation."
	@echo "clean:        Delete all built files."

#===================================================================
# EOF Makefile
#===================================================================
