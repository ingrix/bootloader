.code16
.text
.globl _start;
jmp _start
msg: .ascii "Booting..."
endmsg:
_start:
  movw $msg, %si

  xorw %dx, %dx
  movw %dx, %ds
  cld

char:

  movb $0x0e, %ah
  lodsb #load from si to %al
  int $0x10

  cmp $endmsg, %si
  jne char

  # move cursor to row 2, col 0
  xor %dl, %dl
  xor %bx, %bx
  movb $0x1, %dh
  mov $2, %ah
  int $0x10

loop:
  jmp loop
  . = 510
  .byte 0x55
  .byte 0xaa
