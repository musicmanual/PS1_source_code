.psx
.create "BldPSX\Prog.bin", 0x80010000
.org 0x80010000

.definelabel UserRam, 0x00020000
JoyData equ UserRam+0x200

; ============================================================
; PS1 CONTROLLER TEST
;
; Yellow Circle   = Any digital button pressed OR right stick
;                   moved away from center
;
; Yellow Triangle = No digital buttons pressed AND right stick
;                   centered
;
; Includes:
; Select, Start, L3, R3
; Up, Down, Left, Right
; L1, L2, R1, R2
; Triangle, Circle, Cross, Square
; Right Analog Stick X/Y
;
; BIOS controller input: InitPad / StartPad
; GPU drawing: GP0 flat-shaded triangles
; ============================================================

    li sp,UserRam

; ============================================================
; GPU INITIALIZATION
; ============================================================

    lui a0,0x1F80

    ; GP1(00h): Reset GPU
    li t0,0x00000000
    sw t0,0x1814(a0)

    ; GP1(03h): Display enable
    li t0,0x03000000
    sw t0,0x1814(a0)

    ; GP1(08h): 320x240 display mode
    li t0,0x08000001
    sw t0,0x1814(a0)

    ; Horizontal display range
    li t0,0x06C60260
    sw t0,0x1814(a0)

    ; Vertical display range
    li t0,0x07042018
    sw t0,0x1814(a0)

    ; Drawing attributes
    li t0,0xE1000400
    sw t0,0x1810(a0)

    ; Drawing area top-left
    li t0,0xE3000000
    sw t0,0x1810(a0)

    ; Drawing area bottom-right
    li t0,0xE403BD3F
    sw t0,0x1810(a0)

    ; Drawing offset
    li t0,0xE5000000
    sw t0,0x1810(a0)

; ============================================================
; INITIALIZE CONTROLLER
; ============================================================

    ; B(12h): InitPad
    li t0,0xB0
    li t1,0x12

    li a0,JoyData
    li a1,0x22
    li a2,JoyData+0x30
    li a3,0x22

    jalr t0
    nop

    ; B(13h): StartPad
    li t0,0xB0
    li t1,0x13

    jalr t0
    nop

; ============================================================
; MAIN LOOP
; ============================================================

MainLoop:

    ; Small delay
    li t0,0x8000

DelayLoop:
    addiu t0,t0,-1
    bnez t0,DelayLoop
    nop

; ============================================================
; CHECK DIGITAL BUTTONS
; ============================================================

    li t0,JoyData

    ; Read both digital button bytes
    lhu t1,2(t0)
    nop

    ; If any digital button is pressed, show circle
    li t2,0xFFFF
    bne t1,t2,ShowCircle
    nop

; ============================================================
; CHECK RIGHT ANALOG STICK
;
; Expected standard DualShock analog-pad response:
;
; JoyData+1 = Controller ID (0x73 in analog-pad mode)
; JoyData+4 = Right stick X
; JoyData+5 = Right stick Y
;
; Axis values:
; 0x00 = one extreme
; 0x80 = approximately center
; 0xFF = opposite extreme
;
; Dead zone:
; 0x60 through 0xA0 = considered centered
; ============================================================

    li t0,JoyData

    ; Check controller ID
    lbu t3,1(t0)
    nop

    li t4,0x73

    ; If not in analog-pad mode, skip axis checks
    bne t3,t4,ShowTriangle
    nop

; ============================================================
; RIGHT STICK X
; ============================================================

    lbu t3,4(t0)
    nop

    ; X < 0x60 means moved left
    sltiu t4,t3,0x60
    bnez t4,ShowCircle
    nop

    ; X > 0xA0 means moved right
    sltiu t4,t3,0xA1
    beqz t4,ShowCircle
    nop

; ============================================================
; RIGHT STICK Y
; ============================================================

    lbu t3,5(t0)
    nop

    ; Y < 0x60 means moved up
    sltiu t4,t3,0x60
    bnez t4,ShowCircle
    nop

    ; Y > 0xA0 means moved down
    sltiu t4,t3,0xA1
    beqz t4,ShowCircle
    nop

    ; No digital buttons pressed and right stick centered
    j ShowTriangle
    nop

; ============================================================
; ANY BUTTON PRESSED OR RIGHT STICK MOVED
; ============================================================

ShowCircle:

    li a0,0x02000000
    jal CLS
    nop

    jal DrawCircle
    nop

    j MainLoop
    nop

; ============================================================
; NO BUTTON PRESSED AND RIGHT STICK CENTERED
; ============================================================

ShowTriangle:

    li a0,0x02000000
    jal CLS
    nop

    jal DrawTriangle
    nop

    j MainLoop
    nop

; ============================================================
; CLS: CLEAR SCREEN TO BLACK
; ============================================================

CLS:

    lui a1,0x1F80

    ; GP0(02h): Fill rectangle, black
    sw a0,0x1810(a1)

    ; Position (0,0)
    li t0,0x00000000
    sw t0,0x1810(a1)

    ; Height 240, width 320
    li t0,0x00F00140
    sw t0,0x1810(a1)

    jr ra
    nop

; ============================================================
; DRAW YELLOW TRIANGLE
; ============================================================

DrawTriangle:

    lui t4,0x1F80

    ; GP0(20h): Flat-shaded yellow triangle
    li t0,0x2000FFFF
    sw t0,0x1810(t4)

    ; Vertex 1: (160,70)
    li t0,0x004600A0
    sw t0,0x1810(t4)

    ; Vertex 2: (110,170)
    li t0,0x00AA006E
    sw t0,0x1810(t4)

    ; Vertex 3: (210,170)
    li t0,0x00AA00D2
    sw t0,0x1810(t4)

    jr ra
    nop

; ============================================================
; DRAW YELLOW CIRCLE
; Approximation using 8 filled triangle sectors
; Center = (160,120)
; ============================================================

DrawCircle:

    lui t4,0x1F80

    ; Sector 1: top -> upper-right
    li t0,0x2000FFFF
    sw t0,0x1810(t4)

    ; Center (160,120)
    li t0,0x007800A0
    sw t0,0x1810(t4)

    ; Top (160,80)
    li t0,0x005000A0
    sw t0,0x1810(t4)

    ; Upper-right (188,92)
    li t0,0x005C00BC
    sw t0,0x1810(t4)

    ; Sector 2: upper-right -> right
    li t0,0x2000FFFF
    sw t0,0x1810(t4)

    li t0,0x007800A0
    sw t0,0x1810(t4)

    li t0,0x005C00BC
    sw t0,0x1810(t4)

    ; Right (200,120)
    li t0,0x007800C8
    sw t0,0x1810(t4)

    ; Sector 3: right -> lower-right
    li t0,0x2000FFFF
    sw t0,0x1810(t4)

    li t0,0x007800A0
    sw t0,0x1810(t4)

    li t0,0x007800C8
    sw t0,0x1810(t4)

    ; Lower-right (188,148)
    li t0,0x009400BC
    sw t0,0x1810(t4)

    ; Sector 4: lower-right -> bottom
    li t0,0x2000FFFF
    sw t0,0x1810(t4)

    li t0,0x007800A0
    sw t0,0x1810(t4)

    li t0,0x009400BC
    sw t0,0x1810(t4)

    ; Bottom (160,160)
    li t0,0x00A000A0
    sw t0,0x1810(t4)

    ; Sector 5: bottom -> lower-left
    li t0,0x2000FFFF
    sw t0,0x1810(t4)

    li t0,0x007800A0
    sw t0,0x1810(t4)

    li t0,0x00A000A0
    sw t0,0x1810(t4)

    ; Lower-left (132,148)
    li t0,0x00940084
    sw t0,0x1810(t4)

    ; Sector 6: lower-left -> left
    li t0,0x2000FFFF
    sw t0,0x1810(t4)

    li t0,0x007800A0
    sw t0,0x1810(t4)

    li t0,0x00940084
    sw t0,0x1810(t4)

    ; Left (120,120)
    li t0,0x00780078
    sw t0,0x1810(t4)

    ; Sector 7: left -> upper-left
    li t0,0x2000FFFF
    sw t0,0x1810(t4)

    li t0,0x007800A0
    sw t0,0x1810(t4)

    li t0,0x00780078
    sw t0,0x1810(t4)

    ; Upper-left (132,92)
    li t0,0x005C0084
    sw t0,0x1810(t4)

    ; Sector 8: upper-left -> top
    li t0,0x2000FFFF
    sw t0,0x1810(t4)

    li t0,0x007800A0
    sw t0,0x1810(t4)

    li t0,0x005C0084
    sw t0,0x1810(t4)

    li t0,0x005000A0
    sw t0,0x1810(t4)

    jr ra
    nop

.close