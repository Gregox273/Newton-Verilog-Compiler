# Based on examples from Swarthmore College:
# https://www.cs.swarthmore.edu/~newhall/unixhelp/howto_makefiles.html

BUILDDIR = build
MAIN = rng.blif
EXECUTABLE = ../build/c_compiler
AUTOGEN = urng.vh \
        rng.vh \
        c0.mem \
        c1.mem

all: $(BUILDDIR) $(BUILDDIR)/$(MAIN)

$(BUILDDIR)/%.blif: %.v $(AUTOGEN)
	yosys -p "synth_ice40 -blif $@" $<

$(AUTOGEN): $(EXECUTABLE)
	./../build/c_compiler

$(EXECUTABLE):
	make -C ..

$(BUILDDIR):
	mkdir $@

.PHONY: clean
clean:
	rm -rf $(BUILDDIR)/*