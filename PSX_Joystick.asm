.psx
.create "\BldPSX\Prog.bin", 0x80010000

.org 0x80010000 ; Entry Point Of Code


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

	;       CCPPPPPP - CC = Command PPPPPP=Parameter
;Setup Drawing area
	li t0,0xE1000400
    sw t0,0x1810(a0)			;GP0 Command Port 0x1F801810
;Start 0,0	
	li t0,0xE3000000		;$E3 - Drawing Area TopLeft - %YYYYYYYYYYXXXXXXXXXX (10 bit X Y)
    sw t0,0x1810(a0)			;GP0 Command Port 0x1F801810
	
;End 319x239
	li t0,0xE403BD3F		;$E4 - Drawing area Bottom Right - %YYYYYYYYYYXXXXXXXXXX (10 bit X Y)
    sw t0,0x1810(a0)			;GP0 Command Port 0x1F801810
;Offset 0
	li t0,0xE5000000		;$E5 - Drawing Offset - %YYYYYYYYYYYXXXXXXXXXXXX
    sw t0,0x1810(a0)			;GP0 Command Port 0x1F801810


	li sp,UserRam		;Init Stack Pointer
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


.definelabel UserRam,0x00020000	  ;Address of our program ram

PlayerX equ 0x104
PlayerY equ 0x108
JoyData equ UserRam+0x200

			; BBGGRR
    li a0,0x02000000	;$02 - Fill Area 1- 0xBBBBBB - Background 
	jal CLS			
	nop
	
;B(12h) InitPad(buf1,siz1,buf2,siz2)

	li t0,0xB0			;Bios Functions
	li t1,0x12			;12: InitPad
	
	la a0,JoyData		;Pad Dest
	li a1,0x22			;BufferSize
	li a2,JoyData+0x30	;Pad Dest 2
	li a3,0x22			;BufferSize 2
	jalr t0
	nop 
	
;B(13h) StartPad()

	li t0,0xB0			;Bios Functions
	li t1,0x13			;13: StartPad
	jalr t0
	nop 
	
	
;Set up player start pos
	
	li t7,UserRam		;Point T7 to our ram
	li t8,0
	sw t8,PlayerX(t7)	;Set Xpos=0
	sw t8,PlayerY(t7)	;Set Ypos=0
	
	jal DrawPlayer		;Show Start pos
	nop
	 
	 
InfLoop:

	li t0,0x40000		;Delay
Delay:	
	addi t0,t0,-1		;Crude delay loop
	bnez t0,Delay
	nop

	
;Get Joystick directions
	
	li a3,JoyData
	lbu a3,2(a3)		;Read in joystick directions
	nop
	
	li t1,255
	
	beq t1,a3,InfLoop	;No Direction Pressed?
	nop 
	
	
	addi sp,sp,-4		;Subtract 4 from Stack pointer
	sw a3,0(sp)			;Put the register A3 onto the stack
	
		jal RemovePlayer	;Remove old sprite
		nop
		
	lw a3,0(sp)			;Pop the register A3 off the stack
	addi sp,sp,4		;Add 4 to the Stack pointer
		
		
		
	li t7,UserRam		;Point T7 to our ram
	lw a0,PlayerX(t7)	;Set Xpos=0
	lw a1,PlayerY(t7)	;Set Ypos=0
	
;Test Right
	andi t0,a3,0b00100000	;R button
	bnez t0,NotRight	;Right Pressed?
	nop 
	li t0,320-48		;Screen Right edge
	beq t0,a0,NotRight	;At screen Limit?
	nop
	addi a0,a0,1		;Move Right!
NotRight:	

;Test Left
	andi t0,a3,0b10000000	;L button
	bnez t0,NotLeft		;Left Pressed?
	nop 
	li t0,0				;Screen Left edge
	beq t0,a0,NotLeft	;At screen Limit?
	nop
	addi a0,a0,-1		;Move Left!
NotLeft:	
	
;Test Down
	andi t0,a3,0b01000000	;D button
	bnez t0,NotDown	;Down Pressed?
	nop 
	li t0,240-14-48		;Screen Bottom edge
	beq t0,a1,NotDown	;At screen Limit?
	nop
	addi a1,a1,1		;Move Down!
NotDown:	

;Test Up
	andi t0,a3,0b00010000	;U button
	bnez t0,NotUp		;Up Pressed?
	nop 
	li t0,0				;Screen Top edge
	beq t0,a1,NotUp		;At screen Limit?
	nop
	addi a1,a1,-1		;Move Up!
NotUp:	

	sw a0,PlayerX(t7)	;Set Xpos=0
	sw a1,PlayerY(t7)	;Set Ypos=0
	
	
	
	jal DrawPlayer		;Draw New Pos
	nop
	
	j InfLoop			;Wait forever
	nop 				;Delay Slot
	
	
	
  
CLS:		;Clear the screen
	;       CCPPPPPP - CC = Command PPPPPP=Parameter
	
	lui a1,0x1F80 		;IO_BASE 
	
			; BBGGRR	;$02 - Fill Area 1- 0xBBBBBB - Background 
    sw a0,0x1810(a1)	;GP0 Command Port 0x1F801810
	
    li t0,0x00000000	;$02 - Fill Area 2-0xYYYYXXXX - Topleft
    sw t0,0x1810(a1)	;GP0 Command Port 0x1F801810
	
		; 	HHHHWWWW  	$EF x $137 = 239 x 319
    li t0,0x0EF0013F	;$02 - Fill Area 3-0xHHHHWWWW - HeightWidth
	sw t0,0x1810(a1)	;GP0 Command Port 0x1F801810

	jr ra				;Return
	nop
  
  
  
  
 
RemovePlayer: 
	li t7,UserRam		;Point T7 to our ram
	lw a0,PlayerX(t7)	;Get Xpos
	lw a1,PlayerY(t7)	;Get Ypos
	
	li a2,48+16			;Width
	li a3,48			;Height
		
			; BBGGRR
    li s1,0x020F000F	;$02 - Fill Area 1- 0xBBBBBB - Background 
	
ClearArea:
	lui t4,0x1F80 	;IO_BASE
	
			; BBGGRR	;$02 - Fill Area 1- 0xBBBBBB - Background 
    sw s1,0x1810(t4)	;GP0 Command Port 0x1F801810

;Byte 1: XY Pos - 0xYYYYXXXX 
	sll t3,a1,16 		;0xYYYY----
	addu t3,a0 			;0x----XXXX	
    sw t3,0x1810(t4)	;GP0 Command Port 0x1F801810
	;Xpos seems to be limited to multiples of 16
	
	
;Byte 2: Width/Height - 0xHHHHWWWW	
	;   HHHHWWWW
	sll t3,a3,16 		;0xHHHH----
	addu t3,a2 			;0x----WWWW
	sw t3,0x1810(t4) 	;GP0 Command Port 0x1F801810
    
	jr ra				;Return
	nop
  
  
  
DrawPlayer: 
	li t7,UserRam		;Point T7 to our ram
	lw a0,PlayerX(t7)	;Get Xpos
	lw a1,PlayerY(t7)	;Get Ypos

	li a2,48			;Width
	li a3,48			;Height
	la s1,bitmap		;%-BBBBBGGGGGRRRRR Little endian
	
	
DrawBitmap:
	lui t4,0x1F80 		;IO_BASE
	
	;Byte 0: GPU Command
	li t3,0xA0000000	;A0=Send image to Framebuffer
	sw t3,0x1810(t4) 	;GP0 Cpmmand Port 0x1F801810

	;Byte 1: XY Pos - 0xYYYYXXXX 
	sll t3,a1,16 		;0xYYYY----
	addu t3,a0 			;0x----XXXX
	sw t3,0x1810(t4) 	;GP0 Command Port 0x1F801810

	;Byte 2: Width/Height - 0xHHHHWWWW	
	;   HHHHWWWW
	sll t3,a3,16 		;0xHHHH----
	addu t3,a2 			;0x----WWWW
	sw t3,0x1810(t4) 	;GP0 Command Port 0x1F801810
	
	
	;Calculate loop counter
	srl a2,a2,1			;Convert width to words
	mult a2,a3
	mflo t6				;Word count 
	subiu t6,1
		
	;Byte 3+: Pixel Data 0x22221111
SendBMPData:
	lw t2,0(s1) 		;Get 2 pixels
	addiu s1,4  		;Move to next word
	sw t2,0x1810(t4) 	;send pixel Data - 0x22221111
						;Pixel 1 and 2 data
	bnez t6,SendBMPData 
	subiu t6,1 			;Decrease loop counter (Delay Slot)

	jr ra				;Return
	nop
	
  
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  
Bitmap:
	.incbin "\ResPSX\RawBGR.RAW" ;%-BBBBBGGGGGRRRRR Little endian
	.align 4
	
.close

