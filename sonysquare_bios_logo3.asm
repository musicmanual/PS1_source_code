; ============================================================
; PS1 SCPH-1001 BIOS LOGO - STAGED EMBED VERSION
; Assembler: ARMIPS
;
; Purpose:
;   Keep the proven BIOS Shell entry behavior, but divide the
;   embedded SCPH-1001 Shell into labelled .incbin sections.
;
; IMPORTANT:
;   These sections are grouped by the BIOS address ranges and
;   the GPU-related routines they contain. The support sections
;   are intentionally retained because the logo path calls code
;   elsewhere and reads shared state/data elsewhere in the Shell.
;   This is a better-organized full Shell image, NOT yet a
;   minimal logo-only extraction.
;
; BIOS Shell image:
;   BIOS file offset : 0x18000
;   RAM destination  : 0x80030000
;   Total size       : 0x67FF0 bytes
;
; Runtime entry:
;   A0 = 7, matching the argument observed at the BIOS call site.
; ============================================================

.psx
.create "BldPSX\Prog.bin", 0x80010000

; ------------------------------------------------------------
; EXE ENTRY POINT
; ------------------------------------------------------------
.org 0x80010000

Start:
    ; Keep the stack setup from the working version.
    li      sp, 0x801FF000

    ; Same argument observed at the original BIOS Main() call.
    li      a0, 7

    ; Enter the embedded Shell as a function.
    jal     ShellEntry
    nop

ShellReturned:
    j       ShellReturned
    nop

; ============================================================
; SHELL IMAGE / STAGE 0 - ORIGINAL ENTRY BYTES
; ============================================================
.org 0x80030000

ShellEntry:
    ; BIOS file 0x18000..0x1808F -> RAM 0x80030000..0x8003008F
    ; These are the first 0x90 bytes of the Shell image.
    .incbin "scph1001.bin", 0x18000, 0x90

; ------------------------------------------------------------
; EXPERIMENTAL / WORKING LOGO HOLD PATCH
; ------------------------------------------------------------
LogoHold:
    ; Replaces original Shell bytes at 0x80030090..0x80030097.
    j       LogoHold
    nop

; ============================================================
; STAGE 1 - SHELL STARTUP / PRE-RENDERER INITIALIZATION
; ============================================================
; Destination: 0x80030098
; BIOS file : 0x18098
; Length    : 0x10AEC
; End       : 0x80040B84
;
; This is the original Shell code/data before the main graphics
; record renderer. It includes startup/control-flow code and
; shared helpers. The renderer caller at 0x80040570 is in this
; range. It is not exclusively initialization code.
; ============================================================
.org 0x80030098

Stage1_ShellStartupAndPreRenderer:
    .incbin "scph1001.bin", 0x18098, 0x10AEC

; ============================================================
; STAGE 2 - MAIN GRAPHICS-RECORD RENDERER
; ============================================================
; Routine: 0x80040B84
; BIOS file offset: 0x28B84
; Length: 0x640 bytes (through return delay slot at 0x800411C0)
;
; This is the main renderer called by the Shell graphics path.
; It processes the indexed graphics records and invokes the
; primitive/packet helpers in Stage 4.
; ============================================================
.org 0x80040B84

Stage2_GraphicsRecordRenderer:
    .incbin "scph1001.bin", 0x28B84, 0x640

; ============================================================
; SHARED SHELL SUPPORT RANGE A
; ============================================================
; Destination: 0x800411C4
; BIOS file offset: 0x291C4
; Length: 0x6F48
; End: 0x8004810C
;
; Retained byte-for-byte. This address interval contains other
; Shell routines/data needed by the original Shell execution.
; It is not safe to discard merely because it is outside the
; renderer's entry-point range.
; ============================================================
.org 0x800411C4

Stage2A_RendererSupportAndShellCode:
    .incbin "scph1001.bin", 0x291C4, 0x6F48

; ============================================================
; STAGE 3 - GRAPHICS RECORD / PRIMITIVE / PACKET PROCESSING
; ============================================================
; Destination: 0x8004810C
; BIOS file offset: 0x3010C
; Length: 0x84C
; End: 0x80048958
;
; Important routines inside this range:
;   0x800481AC  graphics-record selector/decoder
;   0x8004858C  triangle coordinate scaler
;   0x80048670  quad coordinate scaler
;   0x8004879C  triangle packet builder
;   0x80048868  quad packet builder
;
; The contiguous range also retains nearby helper routines.
; The builders call the shared byte-copy helper at 0x800308B4,
; which is retained in Stage 1's earlier Shell range.
; ============================================================
.org 0x8004810C

Stage3_RecordDecodeGeometryAndPacketBuilders:
    .incbin "scph1001.bin", 0x3010C, 0x84C

; ============================================================
; SHARED SHELL SUPPORT RANGE B
; ============================================================
; Destination: 0x80048958
; BIOS file offset: 0x30958
; Length: 0x7BCC
; End: 0x80050524
;
; Retained original code/data between packet construction and
; the GPU transfer routines. Do not remove until all references
; and shared state have been resolved.
; ============================================================
.org 0x80048958

Stage3A_GraphicsAndShellSupport:
    .incbin "scph1001.bin", 0x30958, 0x7BCC

; ============================================================
; STAGE 4 - CPU/RAM TO GPU VRAM TRANSFER ROUTINE
; ============================================================
; Routine entry: 0x80050524
; BIOS file offset: 0x38524
; Length: 0x2B0
; End: 0x800507D4
;
; This routine prepares and submits a CPU-to-VRAM transfer.
; It is a GPU transfer path, separate from polygon drawing.
; ============================================================
.org 0x80050524

Stage4_CPUToVRAMTransfer:
    .incbin "scph1001.bin", 0x38524, 0x2B0

; ============================================================
; STAGE 5 - GPU VRAM TO CPU READBACK
; ============================================================
; Routine entry: 0x800507D4
; BIOS file offset: 0x387D4
; Length: 0x2A8
; End: 0x80050A7C
;
; Relevant instruction sites inside this routine:
;   0x80050978  writes GP0(01h) Clear Cache
;   0x8005097C  writes GP0(C0h) VRAM-to-CPU copy
;   0x80050A20  sets GP1 DMA direction to GPU-to-CPU
;
; These are instruction locations inside the larger routine,
; not independent function starts. Readback is not the same as
; drawing the logo; it retrieves VRAM contents into RAM.
; ============================================================
.org 0x800507D4

Stage5_VRAMToCPUReadback:
    .incbin "scph1001.bin", 0x387D4, 0x2A8

; ------------------------------------------------------------
; INTERVENING TRANSFER / SHARED HELPER ROUTINES
; Destination: 0x80050A7C | BIOS file: 0x38A7C | Length: 0x74
; Kept because the original Shell code may call these helpers.
; ------------------------------------------------------------
.org 0x80050A7C

Stage5A_TransferSupportHelpers:
    .incbin "scph1001.bin", 0x38A7C, 0x74

; ============================================================
; STAGE 6 - DIRECT GP0 WORD SUBMISSION
; ============================================================
; Routine entry: 0x80050AF0
; BIOS file offset: 0x38AF0
; Length: 0x38
; End: 0x80050B28
;
; This loop reads prepared command words from RAM and writes
; them to the GPU GP0 port at 0x1F801810.
; It submits packets; it does not build their geometry.
; ============================================================
.org 0x80050AF0

Stage6_DirectGP0Submission:
    .incbin "scph1001.bin", 0x38AF0, 0x38

; ============================================================
; STAGE 7 - DMA2 LINKED-LIST SUBMISSION
; ============================================================
; Routine entry: 0x80050B28
; BIOS file offset: 0x38B28
; Length: 0x58
; End: 0x80050B80
;
; Configures GPU DMA direction, MADR, BCR and CHCR. The final
; CHCR write starts the DMA2 linked-list transfer.
; ============================================================
.org 0x80050B28

Stage7_DMA2LinkedListSubmission:
    .incbin "scph1001.bin", 0x38B28, 0x58

; ============================================================
; SHARED SHELL SUPPORT RANGE C
; ============================================================
; Destination: 0x80050B80
; BIOS file offset: 0x38B80
; Length: 0x9928
; End: 0x8005A4A8
;
; Retains additional GPU/Shell helper routines and data used by
; the original code. Some helpers called by the draw-mode routine
; below are located later in the Shell image and are retained in
; the final support section.
; ============================================================
.org 0x80050B80

Stage7A_GPUAndShellSupport:
    .incbin "scph1001.bin", 0x38B80, 0x9928

; ============================================================
; STAGE 8 - GPU DRAW-MODE SETUP
; ============================================================
; Routine entry: 0x8005A4A8
; BIOS file offset: 0x424A8
; Length: 0x98
; End: 0x8005A540
;
; Reads GPUSTAT, forms GP0(E1h) and sends draw-mode words.
; This routine calls helpers at 0x8005A910 and 0x8005A8D0;
; those addresses are retained in the final support section.
; ============================================================
.org 0x8005A4A8

Stage8_GPUDrawModeSetup:
    .incbin "scph1001.bin", 0x424A8, 0x98

; ============================================================
; REMAINING ORIGINAL SHELL CODE / HELPERS / DATA
; ============================================================
; Destination: 0x8005A540
; BIOS file offset: 0x42540
; Length: 0x3DAB0
; End: 0x80097FF0
;
; This tail is preserved because it contains functions/data
; referenced by earlier stages, including draw-mode helpers.
; It is not yet proven safe to remove any of this range.
; ============================================================
.org 0x8005A540

Stage8A_RemainingShellHelpersAndData:
    .incbin "scph1001.bin", 0x42540, 0x3DAB0

.close
