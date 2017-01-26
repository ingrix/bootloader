/* 
 * Code released under the GNU General Public License v. 2.0
 *
 * This is a simple bootloader that loads a linux kernel
*/

.set BOOTSEC, 0x0
.set BOOTSTART, real_start
.set STACKSTART, 0x7c00 # stack should start where the original MBR code was loaded

.code16
.text
.globl _start;
_start:

  cli #disable interrupts until we get everything set up right

  # copy our boot info to 0:0x0600
  movw 256, %cx # 256 words in MBR
  xorw %ax, %ax
  movw %ax, %ds
  movw $0x600, %di # move us to 0x600
  movw $0x7c00, %si # copy from load address, 0x7c00
  rep movsd 

  # jump to the relocated region and normalize cs:ip
  ljmp $0, $real_start


real_start:

  # set data and stack segments properly, set stack space
  xorw %ax, %ax
  movw %ax, %ss
  movw $STACKSTART, %sp
  movw %sp, %bp

  # BIOS should leave the boot drive number in %dl; save it
  pushw %dx

  #sti # re-enable interrupts

  xorw %dx, %dx

  # read increasing memory addresses
  cld 

  # Move cursor to row 1 col 1
  movb $0x1, %dh
  movb $0x1, %ah
  int $0x10


  # determine the active partition
  movw $4, %cx # only 4 partitions in DOS format
  movw $part_table, %si

bootdetect:

  # test if the first byte of the partition entry is 0x80 (bootable/active)
  movb (%si), %al
  cmpb $0x80, %al
  je boot
  addw $0x10, %si
  loop bootdetect

  jmp boot_err
  
boot:

  # print loading message
  movw $load_msg, %di
  call print_msg

  # load the first sector of the partition to 0x7c00 and jump to it
  movw -2(%bp), %di # retrieve drive number
  call print_val_hex
  jmp loop

boot_err:
  movw $booterrmsg, %di
  call print_msg

# do nothing 
loop:
  jmp loop

# compare kernel magic values
# requires %di to be set to address to compare
#test_kern_magic:
#  movw $kern_magic_size, %cx
#  movw $kern_magic, %si
#1:
#  lodsb # move character to %al
#  movb (%di), %ah
#  inc %di
#  cmpb %ah, %al
#  loopz 1b
#
#  # if the strings were not equal then print an error message
#  jnz .Lkern_magic_err
#
#  xorw %ax, %ax
#  ret
#
#.Lkern_magic_err:
#  movw $-1, %ax
#  ret


# %si contains address of msg to print
print_msg:
  movw %di, %si

.Lprintstart:

  movb $0x0e, %ah
  lodsb           #load char into %al

  # end of message is null byte
  test %al, %al
  jz .Lendprint

  int $0x10
  jmp .Lprintstart
.Lendprint:
  ret
.set print_msg_len, . - print_msg

# Send byte in %si
# stomps basically all of the registers
#print_byte_hex:
#
#  movw $hexchars, %di
#  andw $0x00FF, %si # clear upper byte of %si
#
#  movw %si, %bx
#  andb $0xF0, %bl
#  shr $4, %bl
#
#  movb (%bx,%di), %al
#
#  movb $0x0e, %ah
#  int $0x10
#
#  movw %si, %bx
#  andb $0x0F, %bl
#
#  movb (%bx,%di), %al
#
#  movb $0x0e, %ah
#  int $0x10
#
#  ret

# print value in hexadecimal with leading '0x'
# pass value in %di
# no return value
print_val_hex:
  movw $2, %cx # at least print 0x
pstart:
  movw %di, %ax
  andw $0x000F, %ax
  addb $'0', %al # numeric characters
  
  cmpb $'9', %al
  jle ppush # value was less than 10, don't do anything else

  # greater than '9', so add a enough to get to 'A'
  addb $7, %al

ppush:
  pushw %ax
  inc %cx

  shr $4, %di
  testw %di, %di
  jz pend
  jmp pstart

pend:
  # add 0x to the end
  pushw $'x'
  pushw $'0'
pprint:

  popw %ax
  movb $0x0e, %ah
  int $0x10
  loop pprint

  ret


#disk_addr_packet:
#pktsize:
#.byte 0x10 # 16-byte packet
#reserved:
#.byte 0x00
#nblocks:
#.word 0x00
#txbuf:
#.long 0x00
#absblknum:
#.quad 0x00

load_msg: .asciz "Loading drive "
newline: .asciz "\r\n"
booterrmsg: .asciz "No boot drive found...\r\n"
#kern_magic: .ascii "HdrS"
#kern_err_msg: .asciz "Kern magic failed\r\n"
#kern_magic_test: .ascii "HdrS"
#.set kern_magic_size, 4

  . = _start + 0x1be
part_table:

  . = _start + 0x1fe
boot_sig:
  .byte 0x55
  .byte 0xaa
