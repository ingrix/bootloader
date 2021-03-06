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
_start: cli #disable interrupts until we get everything set up right

  # copy our boot info to 0:0x0600
  movw $256, %cx # 256 words in MBR
  xorw %ax, %ax
  movw %ax, %ds
  movw %ax, %es
  movw $0x600, %di # move us to 0x600
  movw $0x7c00, %si # copy from load address, 0x7c00
  cld
  rep movsw

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

  # determine the active partition
  movw $4, %cx # only 4 partitions in DOS format
  movw $part_table, %si
bootdetect:
  movb (%si), %al
  cmpb $0x80, %al # if first byte of partition entry is 0x80 => bootable
  je bootok

  addw $0x10, %si # next part. entry
  loop bootdetect

  jmp nobootparterr # no boot partition found, error
  
bootok:

  # save partition entry
  pushw %si

  # check for LBA addressing, abort if it's not there
  movw -2(%bp), %dx # saved drive number
  movw $0x55aa, %bx # magic number
  movb $0x41, %ah
  int $0x13
  jc drivereaderr # general bios error
  cmpw $0xaa55, %bx # test drive extensions installed
  jne nolba
  andw $1, %cx # test for LBA
  jz nolba

  # copy the LBA address of the drive partition to the disk address packet
  popw %si
  leaw 8(%si), %si
  movw $disk_abs_block_num, %di
  movw $4, %cx
  cld
  rep movsb

  movb $0x42, %ah
  movw $disk_address_packet, %si
  movb -2(%bp), %dl # retrieve drive number to be safe
  int $0x13
  jc drivereaderr

  # everything ok, print loading message
  movw $load_msg, %di
  call print_msg
  ljmp $0,$0x7c00
  
drivereaderr:
  movw $drivereaderrmsg, %di
  jmp do_err

nolba:
  movw $nolbaerrmsg, %di
  jmp do_err

nobootparterr:
  movw $nobootparterrmsg, %di

do_err:
  call print_msg

# do nothing 
loop:
  jmp loop


# %di contains address of msg to print
# stomps %ax, %si
print_msg:
  movw %di, %si

.Lprintstart:

  lodsb           #load char into %al

  # end of message is null byte
  test %al, %al
  jz .Lendprint

  #movb $0x0e, %ah
  #int $0x10
  call print_char
  jmp .Lprintstart
.Lendprint:
  ret

# char should be in %al
print_char:
  movb $0x0e, %ah
  int $0x10
  ret

# print value in hexadecimal with leading '0x'
# pass value in %di
# stomps %ax, %cx, %di
# no return value
print_val_hex:
  movw $2, %cx # at least print 0x
.Lpstart:
  movw %di, %ax
  andw $0x000F, %ax
  addb $'0', %al # numeric characters
  
  cmpb $'9', %al
  jle .Lppush # value was less than 10, don't do anything else

  # greater than '9', so add a enough to get to 'A'
  addb $7, %al

.Lppush:
  pushw %ax
  inc %cx

  shr $4, %di
  testw %di, %di
  jz .Lpend
  jmp .Lpstart

.Lpend:
  # add 0x to the end
  pushw $'x'
  pushw $'0'
.Lpprint:
  popw %ax
  call print_char
  loop .Lpprint

  ret

load_msg: .asciz "Loading... "
#newline: .asciz "\r\n"
drivereaderrmsg: .asciz "drive read failed"
nobootparterrmsg: .asciz "no boot partition"
nolbaerrmsg: .asciz "no LBA"
diskloaderrmsg: .asciz "sector load error "

. = _start + 0x19e
disk_address_packet:
pktsize: .byte 0x10 # packet size
res: .byte 0
ntx: .word 0x01 # transfer 1 block
baddr: .word 0x7c00 # transfer buffer, should be where bootloader started
       .word 0x0
disk_abs_block_num: .long 0x800 # low 32 bits of LBA
                    .long 0x0 # high 32 bits of LBA

  . = _start + 0x1be
part_table:

  . = _start + 0x1fe
boot_sig:
  .byte 0x55
  .byte 0xaa

# Linux kernel stuff, not implemented yet

#kern_magic: .ascii "HdrS"
#kern_err_msg: .asciz "Kern magic failed\r\n"
#kern_magic_test: .ascii "HdrS"
#.set kern_magic_size, 4

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

