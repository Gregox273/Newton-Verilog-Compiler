# Based on examples from Swarthmore College:
# https://www.cs.swarthmore.edu/~newhall/unixhelp/howto_makefiles.html

CC = clang
CXX = clang++

CFLAGS = -g -Wall
LFLAGS = -lm -lyaml

BUILDDIR = build

CSRC = 	main.c \
	icdf.c \
	yaml_parse.c

OBJS = $(CSRC:.c=.o)

MAIN = c_compiler

all: $(MAIN)

debug: CFLAGS += -O0
debug: $(MAIN)
	gdb $(BUILDDIR)/$(MAIN)

$(MAIN): $(OBJS)
	$(CC) $(CFLAGS) $(LFLAGS) -o $(BUILDDIR)/$(MAIN) $(addprefix $(BUILDDIR)/,$(OBJS))

.c.o: $(BUILDDIR)
	$(CC) $(CFLAGS) -c $<  -o $(BUILDDIR)/$@
	
$(BUILDDIR):
	mkdir $(BUILDDIR)	
	
.PHONY: clean
clean:
	rm -rf $(BUILDDIR)/*
