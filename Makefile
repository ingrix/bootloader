PROG=boot.bin
OBJS=bootloader.o

# Configuration
HDDIMG=hdd.img
BLSIZE=446
MAGICOFFSET=510
HDDSIZE=128M

all: $(OBJS)
	ld -o $(PROG) -Ttext=0x600 --oformat=binary $(OBJS) 

%.o: %.s
	as $^ -o $@

.PHONY: run install objdump

install: all
	@echo "Writing $(PROG) to $(HDDIMG) and setting magic number"
	dd if=$(PROG) of=$(HDDIMG) bs=$(BLSIZE) count=1 conv=notrunc 2>&1
	printf "\x55\xaa" | ( dd of=$(HDDIMG) bs=1 count=2 conv=notrunc seek=$(MAGICOFFSET) 2>&1 ) > /dev/null

run: 
	( qemu-system-x86_64 --enable-kvm -hda $(HDDIMG) 2>&1 ) > /dev/null &

init-hdd:
	@if [ -f "$(HDDIMG)" ] ; then echo "$(HDDIMG) exists, please remove first" ; exit ; fi ; \
	truncate -s $(HDDSIZE) $(HDDIMG)

objdump:
	objdump -b binary -m i386 -M addr16 -D $(PROG)
