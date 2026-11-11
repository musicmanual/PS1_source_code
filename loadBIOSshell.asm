; Load and execute the PS1 BIOS shell from an embedded 512 KiB BIOS image.
; Build from the DevToolsMips working directory.
;
; Expected files:
;   ResPSX\PS1_BIOS.BIN       (raw 512 KiB BIOS)
;   BldPSX\                  (output directory)
;
; The BIOS ROM range [0x18000, 0x7FFEF] is copied to RAM
; [0x80030000, 0x80097FEF], matching BIOS LoadRunShell().
;
; NOTE: The PS-X EXE must include/load the embedded data at 0x800A0000.

.psx
.create "BldPSX\Prog.bin", 0x80010000

.org 0x80010000

Start:
    ; BIOSImage is the start of the embedded full BIOS image.
    la      t0, BIOSImage
    li      t4, 0x00018000
    addu    t0, t0, t4

    li      t1, 0x80030000
    li      t2, 0x00067FF0

CopyShell:
    lw      t3, 0(t0)
    nop                         ; protect load->use on MIPS-I load delay
    sw      t3, 0(t1)

    addiu   t0, t0, 4
    addiu   t1, t1, 4
    addiu   t2, t2, -4
    bnez    t2, CopyShell
    nop

    ; BIOS A(44h) = FlushCache().
    li      t0, 0x000000A0
    li      t1, 0x00000044
    jalr    ra, t0
    nop

    ; Original LoadRunShell sets a0 = 0x80030000 before entering shell.
    li      a0, 0x80030000
    jr      a0
    nop

; Embed the complete 512 KiB BIOS image at a non-overlapping RAM address.
.org 0x800A0000
BIOSImage:
    .incbin "ResPSX\scph1001.bin"

.close
