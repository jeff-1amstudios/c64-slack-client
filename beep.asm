SID = $d400

do_beep
	jsr .clear_sid_registers
	lda #15
	sta $d418		; max volume
	lda #20
	sta $d401

	lda #15
	sta SID + 5
	lda #249
	sta SID + 6
	lda #17
	sta SID + 4
	lda #16
	sta SID + 4

	rts
;	poke 54273, a: poke 54272, b
;  poke 54277,136
;  poke 54278,143
;  poke 54276,17
;  for n = 1 to 300: next n
;  poke 54276,16


.clear_sid_registers
	ldx #24
	lda #0
.clear_loop
	sta SID, x
	dex
	bne .clear_loop
	rts