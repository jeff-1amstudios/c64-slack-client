!zone screen

screen_clear
	lda #0
	;sta $d020       ; border color
	;sta $d021       ; background color
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

; ----------------------------------------------------------------------
; A: first row to scroll ( (-1) - to scroll line 1, A=0)
; Y: number of rows to scroll
; ----------------------------------------------------------------------
screen_scroll_lines_tmp !word 0
screen_scroll_nbr_lines !byte 0

screen_scroll_lines_up
	sty screen_scroll_nbr_lines
	ldx #40
	jsr multiply   ; A * X
	stx screen_scroll_lines_tmp
	sta screen_scroll_lines_tmp + 1
	+add16im screen_scroll_lines_tmp, $0400, ZP_TMP_1
	+add16im screen_scroll_lines_tmp, $0428, ZP_TMP_2

	+add16im screen_scroll_lines_tmp, $d800, ZP_TMP_3
	+add16im screen_scroll_lines_tmp, $d828, ZP_TMP_4
;debugger

	; ZP_TMP_1 = pointer to screen dest, ZP_TMP_2, pointer to screen src
	; ZP_TMP_3 = pointer to color ram dest, ZP_TMP_4, pointer to color ram src

.screen_scroll_lines_up_loop
	ldy #39
.screen_scroll_single_line_up_loop
	lda (ZP_TMP_2), y
	sta (ZP_TMP_1), y
	lda (ZP_TMP_4), y
	sta (ZP_TMP_3), y
	dey
	bpl .screen_scroll_single_line_up_loop
	dec screen_scroll_nbr_lines
	beq .screen_scroll_lines_up_exit
	+add16im ZP_TMP_1, 40, ZP_TMP_1
	+add16im ZP_TMP_2, 40, ZP_TMP_2
	+add16im ZP_TMP_3, 40, ZP_TMP_3
	+add16im ZP_TMP_4, 40, ZP_TMP_4
	jmp .screen_scroll_lines_up_loop

.screen_scroll_lines_up_exit 			; clear out last line with space chars
	+add16im ZP_TMP_1, 40, ZP_TMP_1
	ldy #39
	lda #$20
.screen_scroll_lines_up_exit_loop
	sta (ZP_TMP_1), y
	dey
	bpl .screen_scroll_lines_up_exit_loop


	rts
