
; ============================================================
; PS1 BIOS-STYLE ORANGE / AMBER DIAMOND
; ============================================================
; Assembler : armips
; Output    : BldPSX\Prog.bin
; Load addr : 0x80010000
;
; GPU METHOD:
;   CPU writes directly to GP0 / GP1
;   No DMA
;   No GPUSTAT polling between GP0 words
;
; GP0 FIFO:
;   15 words total
;   PS1 GP0 FIFO capacity: 16 words
;
; ============================================================

.psx
.create "BldPSX\Prog.bin", 0x80010000
.org 0x80010000

GPU_BASE equ 0x1F800000
GPU_GP0  equ 0x1810
GPU_GP1  equ 0x1814

; ------------------------------------------------------------
; ENTRY
; ------------------------------------------------------------

Start:

    ; Initialize stack
    li      sp, 0x801FF000

    ; GPU register base
    lui     t0, 0x1F80

; ============================================================
; PART 1 - GPU INITIALIZATION (GP1)
; ============================================================

    ; GP1(00h) - Reset GPU
    li      t1, 0x00000000
    sw      t1, GPU_GP1(t0)

    ; GP1(03h) - Enable display
    li      t1, 0x03000000
    sw      t1, GPU_GP1(t0)

    ; GP1(08h) - Display mode
    ; 320x240, NTSC, 15-bit
    li      t1, 0x08000001
    sw      t1, GPU_GP1(t0)

    ; GP1(06h) - Horizontal display range
    li      t1, 0x06C60260
    sw      t1, GPU_GP1(t0)

    ; GP1(07h) - Vertical display range
    li      t1, 0x07042018
    sw      t1, GPU_GP1(t0)

; ============================================================
; PART 2 - GP0 DRAWING CONFIGURATION
; ============================================================

    ; E1 - Drawing mode
    li      t1, 0xE1000400
    sw      t1, GPU_GP0(t0)

    ; E3 - Drawing area top-left (0,0)
    li      t1, 0xE3000000
    sw      t1, GPU_GP0(t0)

    ; E4 - Drawing area bottom-right (319,239)
    li      t1, 0xE403BD3F
    sw      t1, GPU_GP0(t0)

    ; E5 - Drawing offset (0,0)
    li      t1, 0xE5000000
    sw      t1, GPU_GP0(t0)

; ============================================================
; PART 3 - CLEAR SCREEN
; ============================================================
; GP0(02h) - Fill rectangle
;
; Word 1 = Command + RGB
; Word 2 = Starting XY
; Word 3 = Width + Height
;
; ============================================================

    ; Fill colour
    li      t1, 0x02002040
    sw      t1, GPU_GP0(t0)

    ; Starting position (0,0)
    li      t1, 0x00000000
    sw      t1, GPU_GP0(t0)

    ; Width = 319
    ; Height = 239
    li      t1, 0x00EF013F
    sw      t1, GPU_GP0(t0)

; ============================================================
; PART 4 - DRAW BIOS-STYLE GOURAUD QUADRILATERAL
; ============================================================
;
; GP0 opcode 38h
;
; Gouraud-shaded
; Opaque
; Untextured
; Quadrilateral
;
; Total: 8 GP0 words
;
; Vertex arrangement:
;
;                 V0
;              (160,40)
;                  *
;                 / \
;                /   \
;       V3 *----/-----\----* V1
;       (40,120)       (280,120)
;                \   /
;                 \ /
;                  *
;                 V2
;              (160,200)
;
; Colours:
;   Red-orange = 0x000000B2
;   Amber      = 0x00008CB2
;
; ============================================================

    ; --------------------------------------------------------
    ; WORD 1 - Opcode 38h + Vertex 0 colour
    ; --------------------------------------------------------

    li      t1, 0x380000B2
    sw      t1, GPU_GP0(t0)

    ; --------------------------------------------------------
    ; WORD 2 - Vertex 0 XY
    ; X=160, Y=40
    ; --------------------------------------------------------

    li      t1, 0x002800A0
    sw      t1, GPU_GP0(t0)

    ; --------------------------------------------------------
    ; WORD 3 - Vertex 1 colour
    ; --------------------------------------------------------

    li      t1, 0x00008CB2
    sw      t1, GPU_GP0(t0)

    ; --------------------------------------------------------
    ; WORD 4 - Vertex 1 XY
    ; X=280, Y=120
    ; --------------------------------------------------------

    li      t1, 0x007800B8
    sw      t1, GPU_GP0(t0)

    ; --------------------------------------------------------
    ; WORD 5 - Vertex 2 colour
    ; --------------------------------------------------------

    li      t1, 0x00008CB2
    sw      t1, GPU_GP0(t0)

    ; --------------------------------------------------------
    ; WORD 6 - Vertex 2 XY
    ; X=160, Y=200
    ; --------------------------------------------------------

    li      t1, 0x00C800A0
    sw      t1, GPU_GP0(t0)

    ; --------------------------------------------------------
    ; WORD 7 - Vertex 3 colour
    ; --------------------------------------------------------

    li      t1, 0x000000B2
    sw      t1, GPU_GP0(t0)

    ; --------------------------------------------------------
    ; WORD 8 - Vertex 3 XY
    ; X=40, Y=120
    ; --------------------------------------------------------

    li      t1, 0x00780028
    sw      t1, GPU_GP0(t0)

; ============================================================
; PART 5 - KEEP PROGRAM ALIVE
; ============================================================

Forever:

    j       Forever
    nop

.close
