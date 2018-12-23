# Based on examples from Swarthmore College:
# https://www.cs.swarthmore.edu/~newhall/unixhelp/howto_makefiles.html

include config.local

CC = clang
CXX = clang++

CFLAGS = -g -Wall
LFLAGS = -lm -lyaml -lgsl -lgslcblas

BUILDDIR = build

CSRC = 	main.c \
	icdf.c \
	yaml_parse.c \
	gen_vh.c \
	gen_lookup.c

OBJS = $(CSRC:%.c=$(BUILDDIR)/%.o)

MAIN = c_compiler

all: $(BUILDDIR) $(BUILDDIR)/$(MAIN)

$(BUILDDIR)/%.o: %.c
	$(CC) $(CFLAGS) -DWORKING_DIR=\"$(WD)\" -c $< -o $@


$(BUILDDIR)/$(MAIN): $(OBJS)
	$(CC) $(CFLAGS) $(LFLAGS) $^ -o $@


$(BUILDDIR):
	mkdir $@

debug: CFLAGS += -O0
debug: $(BUILDDIR)/$(MAIN)
	gdb $(BUILDDIR)/$(MAIN)

.PHONY: clean
clean:
	rm -rf $(BUILDDIR)/*
