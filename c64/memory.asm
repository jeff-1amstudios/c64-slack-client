!zone memory

; ----------------------------------------------------------------------
; $FB/$FC: source null-terminated string
; $FD/$FE: dest buffer
; Y: number of bytes to copy
; ----------------------------------------------------------------------
mem_copy

.copy_loop
	lda ($fb), y
	sta ($fd), y
	dey
	bne .copy_loop
	rts

; ----------------------------------------------------------------------
; A: char to set
; $FB/$FC: ptr to memory to set
; $FD/$FE: length of data
; ----------------------------------------------------------------------
; mem_set
; 	ldy #0

; .set_loop
; 	sta ($fb), y
; 	iny
; 	bne .set_loop
; 	+inc16 $fb
; 	+inc16 $fd
; 	jmp .set_loop




.exit
	rts