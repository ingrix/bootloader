PROG=boot.bin
OBJS=bootloader.o

all: $(OBJS)
	ld -o $(PROG) -Ttext=0x7c00 --oformat=binary $(OBJS) 

%.o: %.s
	as $^ -o $@
