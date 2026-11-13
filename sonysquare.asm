
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
    ; BIOS-STYLE ORANGE SONY DIAMOND
    ;
    ; This reproduces the BIOS-observed GP0(38h) packet:
    ; Gouraud-shaded, opaque, untextured quadrilateral.
    ;
    ; BIOS log (640x480 drawing coordinates):
    ;   V0 (192,240) colour 0x000000B2
    ;   V1 (320,112) colour 0x00008CB2
    ;   V2 (320,368) colour 0x00008CB2
    ;   V3 (448,240) colour 0x000000B2
    ;
    ; This program keeps your existing 320x240 display setup,
    ; so the BIOS coordinates are scaled by 1/2:
    ;   V0 (96,120), V1 (160,56),
    ;   V2 (160,184), V3 (224,120).
    ;
    ; The GP0 packet layout and colour values match the BIOS.
    ; Only the vertex coordinates are scaled for this display.
    ; --------------------------------------------------------

    ; WORD 0: GP0(38h) + V0 red-orange colour
    li      t1, 0x380000B2
    sw      t1, GPU_GP0(t0)

    ; WORD 1: V0 XY = (96,120)
    li      t1, 0x00780060
    sw      t1, GPU_GP0(t0)

    ; WORD 2: V1 amber colour
    li      t1, 0x00008CB2
    sw      t1, GPU_GP0(t0)

    ; WORD 3: V1 XY = (160,56)
    li      t1, 0x003800A0
    sw      t1, GPU_GP0(t0)

    ; WORD 4: V2 amber colour
    li      t1, 0x00008CB2
    sw      t1, GPU_GP0(t0)

    ; WORD 5: V2 XY = (160,184)
    li      t1, 0x00B800A0
    sw      t1, GPU_GP0(t0)

    ; WORD 6: V3 red-orange colour
    li      t1, 0x000000B2
    sw      t1, GPU_GP0(t0)

    ; WORD 7: V3 XY = (224,120)
    li      t1, 0x007800E0
    sw      t1, GPU_GP0(t0)

    ; --------------------------------------------------------
    ; KEEP PROGRAM RUNNING
    ; --------------------------------------------------------

Forever:
    j       Forever
    nop

.close
