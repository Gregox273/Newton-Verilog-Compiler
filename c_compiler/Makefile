CC = clang
CXX = clang++

CCFLAGS = -g -Wall

BUILDDIR = build

TARGET = main

all: $(TARGET)

$(TARGET).o: $(TARGET).c $(BUILDDIR)
	$(CC) $(CFLAGS) -o $(BUILDDIR)/$(TARGET).o $(TARGET).c
	
$(BUILDDIR):
	mkdir $(BUILDDIR)	
	
.PHONY: clean
clean:
	rm -rf $(BUILDDIR)/*