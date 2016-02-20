ASM = wla-z80
ASMFLAGS = -o
LD = wlalink
LDFLAGS = -vds

SFILES = ButtonTest.asm
IFILES = assets/backgroundPalette.inc assets/spritesPalette.inc
OFILES = ButtonTest.o
OUT = ButtonTest.gg

all: $(OFILES) $(IFILES) makefile
	echo [objects] > linkfile
	echo $(OFILES) >> linkfile
	$(LD) $(LDFLAGS) linkfile $(OUT)

%.o: %.asm
	$(ASM) $(ASMFLAGS) $< $@

clean:
	rm -f $(OFILES) core *~ *.sym linkfile $(OUT)
