
; ============================================================
; PS1 ORANGE BIOS LOGO
; GPU-only MIPS drawing demo
; Assembler: armips
; Load address: 0x80010000
; Output: BldPSX\Prog.bin
;
; Draws:
;   1. Black background
;   2. Orange Gouraud-shaded diamond
;
; GP0 opcode 38h:
;   Gouraud-shaded, opaque, untextured quad
; ============================================================

.psx
.create "BldPSX\Prog.bin", 0x80010000
.org 0x80010000

GPU_GP0 equ 0x1810
GPU_GP1 equ 0x1814

Start:

    ; --------------------------------------------------------
    ; Stack and GPU base address
    ; --------------------------------------------------------

    li      sp, 0x801FF000
    lui     t0, 0x1F80

    ; --------------------------------------------------------
    ; GPU DISPLAY INITIALIZATION
    ; --------------------------------------------------------

    ; GP1(00): GPU reset
    li      t1, 0x00000000
    sw      t1, GPU_GP1(t0)

    ; GP1(03): Enable display
    li      t1, 0x03000000
    sw      t1, GPU_GP1(t0)

    ; GP1(08): 320x240 display mode
    li      t1, 0x08000001
    sw      t1, GPU_GP1(t0)

    ; GP1(06): Horizontal display range
    li      t1, 0x06C60260
    sw      t1, GPU_GP1(t0)

    ; GP1(07): Vertical display range
    li      t1, 0x07042018
    sw      t1, GPU_GP1(t0)

    ; --------------------------------------------------------
    ; GP0 DRAWING CONFIGURATION
    ; --------------------------------------------------------

    ; E1: Drawing mode
    li      t1, 0xE1000400
    sw      t1, GPU_GP0(t0)

    ; E3: Drawing area top-left (0,0)
    li      t1, 0xE3000000
    sw      t1, GPU_GP0(t0)

    ; E4: Drawing area bottom-right (319,239)
    li      t1, 0xE403BD3F
    sw      t1, GPU_GP0(t0)

    ; E5: Drawing offset (0,0)
    li      t1, 0xE5000000
    sw      t1, GPU_GP0(t0)

    ; --------------------------------------------------------
    ; BLACK BACKGROUND
    ;
    ; GP0(02): Fill rectangle
    ; Word 0 = command + colour
    ; Word 1 = destination XY
    ; Word 2 = width + height
    ; --------------------------------------------------------

    ; Black
    li      t1, 0x02000000
    sw      t1, GPU_GP0(t0)

    ; Position X=0, Y=0
    li      t1, 0x00000000
    sw      t1, GPU_GP0(t0)

    ; Width=320, Height=240
    li      t1, 0x00F00140
    sw      t1, GPU_GP0(t0)

    ; --------------------------------------------------------
    ; ANIMATED BIOS-STYLE ORANGE SONY DIAMOND
    ;
    ; Uses the BIOS-observed GP0(38h) Gouraud quad.
    ; The complete diamond moves horizontally, then reverses.
    ; X offset moves between 32 and 192; Y stays centred.
    ; --------------------------------------------------------

    li      s0, 32              ; current X offset
    li      s1, 1               ; direction: +1 right, -1 left

MoveLoop:
    ; WORD 0: GP0(38h), V0 red-orange
    li      t1, 0x380000B2
    sw      t1, GPU_GP0(t0)

    ; WORD 1: V0 = (X,120)
    addu    t1, s0, zero
    li      t2, 120
    sll     t2, t2, 16
    or      t1, t1, t2
    sw      t1, GPU_GP0(t0)

    ; WORD 2: V1 amber
    li      t1, 0x00008CB2
    sw      t1, GPU_GP0(t0)

    ; WORD 3: V1 = (X+64,56)
    addiu   t1, s0, 64
    li      t2, 56
    sll     t2, t2, 16
    or      t1, t1, t2
    sw      t1, GPU_GP0(t0)

    ; WORD 4: V2 amber
    li      t1, 0x00008CB2
    sw      t1, GPU_GP0(t0)

    ; WORD 5: V2 = (X+64,184)
    addiu   t1, s0, 64
    li      t2, 184
    sll     t2, t2, 16
    or      t1, t1, t2
    sw      t1, GPU_GP0(t0)

    ; WORD 6: V3 red-orange
    li      t1, 0x000000B2
    sw      t1, GPU_GP0(t0)

    ; WORD 7: V3 = (X+128,120)
    addiu   t1, s0, 128
    li      t2, 120
    sll     t2, t2, 16
    or      t1, t1, t2
    sw      t1, GPU_GP0(t0)

    ; Advance the horizontal position.
    addu    s0, s0, s1

    ; Reverse at the right edge (X=192).
    slti    t1, s0, 193
    bnez    t1, CheckLeft
    nop
    li      s0, 192
    li      s1, -1

CheckLeft:
    ; Reverse at the left edge (X=32).
    slti    t1, s0, 32
    beqz    t1, DelayFrame
    nop
    li      s0, 32
    li      s1, 1

DelayFrame:
    ; Simple CPU delay to make the motion visible.
    ; This is not synchronised to VBlank.
    li      t3, 180000
DelayLoop:
    addiu   t3, t3, -1
    bnez    t3, DelayLoop
    nop

    j       MoveLoop
    nop

.close
