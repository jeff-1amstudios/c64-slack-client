!zone screen

screen_clear
	lda #0
	sta $d020       ; border color
	sta $d021       ; background color
	lda #147        ; clear screen
	jsr CHROUT

	lda #0		; disable all sprites
	sta $d015
	rts

screen_enable_lowercase_chars
	lda #23
	sta $d018
	rts

; ----------------------------------------------------------------------
; X: row
; Y: column
; $FB/$FC: null-terminated string
; ----------------------------------------------------------------------
screen_print_str
	clc
	jsr PLOT
	ldy #0
.print_str_loop
	lda ($fb), y
	cmp #0
	beq .print_str_exit
	jsr CHROUT
	iny
	bne .print_str_loop
	; if we overflowed Y, inc $fc
	inc $fc
	ldy #0
	jmp .print_str_loop

.print_str_exit
	rts

; ----------------------------------------------------------------------
; X: row
; Y: column
; $FB/$FC: null-terminated string
; ----------------------------------------------------------------------
screen_print_str_2
	ldy #0
.print_str_loop_2
	lda ($fb), y
	cmp #0
	beq .print_str_exit_2
	jsr CHROUT
	iny
	bne .print_str_loop
	; if we overflowed Y, inc $fc
	inc $fc
	ldy #0
	jmp .print_str_loop

.print_str_exit_2
	rts

screen_clear_background
	ldx #$00                         
.screen_clear_background_loop
	lda #$00                         
	sta $d800,x  
	sta $d900,x
	sta $da00,x
	sta $dae8,x
	inx           
	bne .screen_clear_background_loop
	rts
