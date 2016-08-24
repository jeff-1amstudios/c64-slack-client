!cpu 6510
!to "./build/tester.prg",cbm

RSSTAT = $0297
GETIN = $FFE4
CHKIN = $FFC6
SETLFS = $FFBA
OPEN = $FFC0
SETNAM = $FFBD
CHROUT = $FFD2
OUTB = $00F7

* = $0801                               ; BASIC start address (#2049)
!byte $0d,$08,$dc,$07,$9e,$20,$34,$39   ; BASIC loader to start at $c000...
!byte $31,$35,$32,$00,$00,$00           ; puts BASIC line 2012 SYS 49152

* = $c000
		ldx #<.out_buf
		sta OUTB
		ldx #>.out_buf
		sta OUTB+1
		lda #3          ; file #
		ldx #2          ; 2 = rs-232 device
		ldy #0        	; no cmd
		jsr SETLFS		

		lda #2
		ldx #<.file_name
		ldy #>.file_name
		jsr SETNAM

		jsr OPEN

		lda #0
		;sta $d020       ; border color
		;sta $d021       ; background color
		lda #147
		jsr CHROUT


		ldx #3
        jsr CHKIN       ; select file 3 as input channel

.main_loop
        jsr GETIN
        cmp #0
        beq .main_loop
        sta $0400
        ;lda RSSTAT
        ;sta $0410
        jmp .main_loop

.file_name !byte 6, 0
.out_buf !fill 256, 0