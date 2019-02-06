# Based on examples from Swarthmore College:
# https://www.cs.swarthmore.edu/~newhall/unixhelp/howto_makefiles.html

BUILDDIR = build
MAIN = rng.blif
EXECUTABLE = ../build/c_compiler
AUTOGEN = urng.vh \
        rng.vh \
        c0.mem \
        c1.mem
VERILOG_SRCS = $(wildcard *.v)

all: $(BUILDDIR) $(BUILDDIR)/$(MAIN)

$(BUILDDIR)/%.blif: %.v $(AUTOGEN) $(VERILOG_SRCS)
	yosys -p "synth_ice40 -blif $@" $(VERILOG_SRCS)

$(AUTOGEN): $(EXECUTABLE)
	./../build/c_compiler

$(EXECUTABLE):
	make -C ..

$(BUILDDIR):
	mkdir $@

.PHONY: clean
clean:
	rm -rf $(BUILDDIR)/*