!zone memory

; ----------------------------------------------------------------------
; $FB/$FC: source null-terminated string
; $FD/$FE: dest buffer
; ----------------------------------------------------------------------
mem_copy
	ldy #0

.copy_loop
	lda ($fb), y
	sta ($fd), y
	cmp #0          ; If char is 0, then exit
	beq .exit
	iny
	bne .copy_loop
	+inc16 $fb
	+inc16 $fd
	jmp .copy_loop

; ----------------------------------------------------------------------
; A: char to set
; $FB/$FC: ptr to memory to set
; $FD/$FE: length of data
; ----------------------------------------------------------------------
mem_set
	ldy #0

.set_loop
	sta ($fb), y
	iny
	bne .set_loop
	+inc16 $fb
	+inc16 $fd
	jmp .set_loop




.exit
	rts