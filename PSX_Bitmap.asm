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


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

			; BBGGRR
    li a0,0x02000000	;$02 - Fill Area 1- 0xBBBBBB - Background 
	jal CLS			
	nop

	li a0,16			;X pos
	li a1,8				;Y pos
	li a2,48			;Width
	li a3,48			;Height
	la s1,bitmap		;%-BBBBBGGGGGRRRRR Little endian	
	jal DrawBitmap
	nop
	
InfLoop:
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
  
  
DrawBitmap:
	lui t4,0x1F80 	;IO_BASE
	
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

