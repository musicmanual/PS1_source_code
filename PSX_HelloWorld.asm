

.psx						;Tell The assembler what system 
								;Were' building for
								
.create "BldPSX\Prog.bin", 0x80010000

	.org 0x80010000 		;Entry Point Of Code




.definelabel UserRam,0x00020000	  ;Address of our program ram

CursorX equ 0x100 		;Defined symbols CursorX EQUals 0x100
CursorY equ 0x101




	lui     a0,0x1F80 ;IO_BASE 

; Setup Screen Mode
		;   CCPPPPPP - CC = Command PPPPPP=Parameter
    li t0,0x00000000		;$00=Reset
    sw t0,0x1814(a0)	       ;GP0 Command Control 0x1F801814
	
    li t0,0x03000000		;$03=Display Enable
    sw t0,0x1814(a0)	       ;GP0 Command Control 0x1F801814
	
    li t0,0x08000001		;$80=Display Mode %RwI2VHWW (320x240 16bpp)
    sw t0,0x1814(a0)	       ;GP0 Command Control 0x1F801814
	
    li t0,0x06C60260		;$06= H Display Range 0xXXXxxx	 (3168-608)
    sw t0,0x1814(a0)	       ;GP0 Command Control 0x1F801814
	
    li t0,0x07042018        ;$07= V Display Range %yyyyyyyyyyYYYYYYYYYY	 (264-24)
	sw t0,0x1814(a0)	       ;GP0 Command Control 0x1F801814

;Setup Screen Area	
	li t0,0xE1000400
    sw t0,0x1810(a0)			;GP0 Command Port 0x1F801810
	
	li t0,0xE3000000		;$E3 - Drawing Area TopLeft - %YYYYYYYYYYXXXXXXXXXX
    sw t0,0x1810(a0)			;GP0 Command Port 0x1F801810
	
	li t0,0xE403BD3F		;$E4 - Drawing area Bottom Right - %YYYYYYYYYYXXXXXXXXXX
    sw t0,0x1810(a0)			;GP0 Command Port 0x1F801810
	
	li t0,0xE5000000		;$E5 - Drawing Offset - %YYYYYYYYYYYXXXXXXXXXXXX
    sw t0,0x1810(a0)			;GP0 Command Port 0x1F801810
	
	li sp,UserRam			;Init Stack Pointer
	
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  
	jal Cls				;Clear the screen
	nop
  
	la a0,text 			;A0 = String (255 terminated)
	jal PrintString		;Print String 
	nop
  
	jal NewLine         ;Move down a line
	nop
	
	la a0,text 			;A0 = String (255 terminated)
	jal PrintString		;Print String 
	nop
  
  
InfLoop:
	j InfLoop			;Wait forever
	nop 				;Delay Slot
  
Text:
	.db "Hello World!",255
	.align 4 			;Align 32-Bit

	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  
	
Cls:
	lui     a0,0x1F80 ;IO_BASE 
	
	;Fill Screen
		;   02BBGGRR
    li t0,0x027F0000		;$02 - Fill Area 1- 0xBBGGRR - Background 
    sw t0,0x1810(a0)			;GP0 Command Port 0x1F801810
		;   YYYYXXXX
    li t0,0x00000000		;$02 - Fill Area 2-0xYYYYXXXX - Topleft
    sw t0,0x1810(a0)			;GP0 Command Port 0x1F801810
		; 	HHHHWWWW  $EF x $137 = 239 x 319
    li t0,0x0EF0013F		;$02 - Fill Area 3-0xHHHHWWWW - HeightWidth
	sw t0,0x1810(a0)			;GP0 Command Port 0x1F801810

	
	li t7,UserRam		;Point T7 to our ram
  
	li t8,0
	sb t8,CursorX(t7)	;Set Xpos=0
	sb t8,CursorY(t7)	;Set Ypos=0
	
	jr ra
	nop

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  
MyFont:
	.incbin "ResALL\Font96.fnt"



PrintChar:	;PrintChar A1
	
		;Calculate Font source address
		subiu a1,32			;No Characters below 32
		la t6,MyFont 		;Font Address
		
		sll a1,3 			;*3 (8 bytes per tile) 
		addu t6,a1 			;add to font base
		
		
		;Load XY pos for GPU commands
		li t0,UserRam		
		lbu t1,CursorX(t0)	;Xpos in chars
		nop					;Load delay Slot
		sll t1,3 		;*8
		
		lbu t2,CursorY(t0)	;Ypos in chars
		nop					;Load delay Slot
		sll t2,3 		;*8

		
		;Set up destination area
		lui t4,0x1F80 		;IO_BASE 0x1F800000
		
		;Byte 0: GPU Command
		li t3,0xA0000000	;A0=Send image to Framebuffer
		sw t3,0x1810(t4) 	;GP0 Cpmmand Port 0x1F801810

		;Byte 1: XY Pos - 0xYYYYXXXX 
		sll t3,t2,16 		;0xYYYY----
		addu t3,t1 			;0x----XXXX
		sw t3,0x1810(t4) 	;GP0 Cpmmand Port 0x1F801810

		;Byte 2: Width/Height - 0xHHHHWWWW
		li t3,0x00080008 	;8x8 Char
		sw t3,0x1810(t4) 	;GP0 Cpmmand Port 0x1F801810

		

		li t2,8				;Height in lines
PrintChar_NextLine:	
		li t1,4				;Width in pairs of pixels
		lb t3,0(t6)
		addiu t6,1
PrintChar_NextWord:

;Calc Pixel 2
			;   -BBBBBGGGGGRRRRR	- Pixel 2 OFF (Blue)
		li t5,0b0011110000000000
					;12------
		andi t0,t3,0b01000000
		beqz t0,PrintChar_DonePixel2
		nop ;   -BBBBBGGGGGRRRRR	- Pixel 2 ON (Yellow)
		li t5,0b0000001111111111
PrintChar_DonePixel2:
		
		sll t5,16				;Move pixel to top word of final word

;Calc Pixel 1
					;12------
		andi t0,t3,0b10000000		
		beqz t0,PrintChar_DrawPixel_1_Off
		nop
			;    -BBBBBGGGGGRRRRR  - Pixel 1 ON (Yellow)
		ori t5,0b0000001111111111
		j PrintChar_DrawPixel1
		nop
		
PrintChar_DrawPixel_1_Off:		
			;    -BBBBBGGGGGRRRRR  - Pixel 1 OFF (Blue)
		ori t5,0b0011110000000000
		
		
PrintChar_DrawPixel1:		
		sw t5,0x1810(t4) 		;send pixel Data - 0x22221111	
		sll t3,2					;Pixel 1 and 2 data
			
		subiu t1,1 		;Repeat for next pixel pair
		bnez t1,PrintChar_NextWord
		nop
	        
			
		subiu t2,1 		;Repeat for next line
		bnez t2,PrintChar_NextLine
		nop
		
		;across one char
		li t0,UserRam	
		lbu t1,CursorX(t0)		;Get Xpos
		nop						;Load delay Slot
		addiu t1,1
		sb t1,CursorX(t0)		;Move across 1 char
	jr ra
	nop
 
 	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


	
PrintString:		;Print String A0

	addi sp,sp,-4		;Subtract 4 from Stack pointer
	sw ra,0(sp)			;Put the register RA onto the stack
	
DrawChars:		
		lbu a1,0(a0) 	;Load a character
		addiu a0,1 		;Move to next Char
		
		li t0,255		;Compare to 255
		beq t0,a1,PrintString_Done	;Done?
		nop
		
		jal PrintChar	;Show Character A0 to the screen
		nop
		
		j DrawChars		;Repeat
		nop
PrintString_Done:	

	lw ra,0(sp)			;Pop the register RA off the stack
	addi sp,sp,4		;Add 4 to the Stack pointer
	
	jr ra				;Return
	nop
	
	
	
NewLine:
	li t7,UserRam			;Get address of ram vars

	lbu t8,CursorY(t7)
	nop						;Load delay Slot

	addiu t8,1				;Move Down
	sb t8,CursorY(t7)		

	li t8,0
	sb t8,CursorX(t7)		;Zero Xpos
	
	jr ra
	nop
	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	

.close					;End our program

