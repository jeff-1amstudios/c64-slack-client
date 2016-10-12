!zone string
; ----------------------------------------------------------------------
; Returns: zero-flag is set if strings are equal
; $FB/$FC: null-terminated string
; $FD/$FE: null-terminated string
; ----------------------------------------------------------------------
string_equals
	ldy #0
.loop
	lda ($fb), y
	cmp ($fd), y
	bne .exit       ; if chars not equal, then return
	ora ($fd), y    ; OR both chars together.
	cmp #0          ; If result is 0, then they are both \0 and string compare is successful
	beq .exit
	iny
	jmp .loop
.exit
	rts

; ----------------------------------------------------------------------
; $FB/$FC: source null-terminated string
; $FD/$FE: dest buffer
; ----------------------------------------------------------------------
string_copy
	ldy #0
.copy_loop
	lda ($fb), y
	sta ($fd), y
	cmp #0          ; If char is 0, then exit
	beq .exit
	cmp #$ff          ; If char is 0xff, then exit
	beq .exit
	iny
	bne .copy_loop
	; if we overflowed Y, inc base pointers
	inc $fc
	inc $fe
	ldy #0
	jmp .copy_loop

; ----------------------------------------------------------------------
; $FB/$FC: source null-terminated string
; Returns length in Y
; ----------------------------------------------------------------------
string_len
	ldy #0
.loop2
	lda ($fb), y
	beq .exit
	iny
	jmp .loop2
