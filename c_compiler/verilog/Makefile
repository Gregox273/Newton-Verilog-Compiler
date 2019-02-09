# Based on examples from Swarthmore College:
# https://www.cs.swarthmore.edu/~newhall/unixhelp/howto_makefiles.html

BUILDDIR = build
SIMDIR = sim
MAIN = rng.blif
EXECUTABLE = ../build/c_compiler
AUTOGEN = urng.vh \
        rng.vh \
        c0.mem \
        c1.mem
VERILOG_SRCS = $(wildcard *.v)

all: $(BUILDDIR) $(BUILDDIR)/$(MAIN)

synthclz: $(BUILDDIR)
	yosys -p "synth_ice40 -top clz -blif $(BUILDDIR)/clz.blif" clz.v

simclz: $(SIMDIR)
	iverilog -Wall -o $(SIMDIR)/clz.vvp clz_tb.v
	vvp $(SIMDIR)/clz.vvp -vcd $(SIMDIR)/clz.vcd
	gtkwave $(SIMDIR)/clz.vcd

simclz_merge_n: $(SIMDIR)
	iverilog -Wall -o $(SIMDIR)/clz_merge_N.vvp clz_merge_N_tb.v
	vvp $(SIMDIR)/clz_merge_N.vvp -vcd $(SIMDIR)/clz_merge_N.vcd
	gtkwave $(SIMDIR)/clz_merge_N.vcd


synthrng: $(BUILDDIR)
	yosys -p "synth_ice40 -top rng -blif $(BUILDDIR)/rng.blif" rng.v

simrng: $(SIMDIR)
	iverilog -Wall -o $(SIMDIR)/rng.vvp rng_tb.v
	vvp $(SIMDIR)/rng.vvp -vcd $(SIMDIR)/rng.vcd
	gtkwave $(SIMDIR)/rng.vcd

$(BUILDDIR)/%.blif: %.v $(AUTOGEN) $(VERILOG_SRCS)
	yosys -p "synth_ice40 -blif $@" $(VERILOG_SRCS)

$(AUTOGEN): $(EXECUTABLE)
	./../build/c_compiler

$(EXECUTABLE):
	make -C ..

$(BUILDDIR):
	mkdir $@

$(SIMDIR):
	mkdir $@

.PHONY: clean
clean:
	rm -rf $(BUILDDIR)/*
