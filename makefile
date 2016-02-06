ASM = wla-z80
ASMFLAGS = -o
LD = wlalink
LDFLAGS = -vds

SFILES = InputTest.asm
IFILES = assets/backgroundPalette.inc assets/spritesPalette.inc
OFILES = InputTest.o
OUT = InputTest.gg

all: $(OFILES) $(IFILES) makefile
	echo [objects] > linkfile
	echo $(OFILES) >> linkfile
	$(LD) $(LDFLAGS) linkfile $(OUT)

%.o: %.asm
	$(ASM) $(ASMFLAGS) $< $@

clean:
	rm -f $(OFILES) core *~ *.sym linkfile $(OUT)
