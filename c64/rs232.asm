!zone rs232

.file_name !byte 6, 0
.output_buffer !fill 256, 0
.input_buffer !fill 256, 0
.tmp !byte 0

; ----------------------------------------------------------------------
; Opens rs232 channel on file #3
; ----------------------------------------------------------------------
rs232_open
		+set16im .input_buffer, RS232_INBUF_PTR
		+set16im .output_buffer, RS232_OUTBUF_PTR

		lda #3          ; file #
		ldx #2          ; 2 = rs-232 device
		ldy #0        ; no cmd
		jsr SETLFS		

		lda #0		; no name
		jsr SETNAM

		lda #%00001000  ; 2400 baud, 8 bits per char
		sta $0293

		jsr OPEN
		rts


; ----------------------------------------------------------------------
; Returns: A
; If no data available, will return immediately with \0 and bit #3 in RSSTAT will be 1
; ----------------------------------------------------------------------
rs232_try_read_byte
		ldx #3
		jsr CHKIN       ; select file 3 as input channel
		jsr GETIN       ; try and read from rs232 buffer
		tay             ; CLRCHN uses A, so move data to Y reg
		jsr CLRCHN
		tya             ; ... and back again
		rts

; ----------------------------------------------------------------------
; A: byte to write
; ----------------------------------------------------------------------
rs232_write_byte
		ldx #3
		tay
		jsr CHKOUT       ; select file 3 as input channel
		tya
		jsr CHROUT
		jsr CLRCHN
		rts

; ----------------------------------------------------------------------
; $FB/$FC: source null-terminated string
; ----------------------------------------------------------------------
rs232_send_string
		ldx #3
		jsr CHKOUT       ; select file 3 as input channel
		ldy #0
.send_string_loop
		lda ($fb), y
		beq .send_string_done
		jsr CHROUT
		iny
		jmp .send_string_loop
		
.send_string_done
		jsr CLRCHN
		rts

; ----------------------------------------------------------------------
; $FB/$FC: source bytes
; A: number of bytes to send
; ----------------------------------------------------------------------
rs232_send_buffer
		sta .tmp
		ldx #3
		jsr CHKOUT       ; select file 3 as input channel
		ldx .tmp      	 ; X now holds the number of chars to send
		ldy #0
.send_buffer_loop
		lda ($fb), y
		jsr CHROUT
		iny
		dex
		beq .send_buffer_done
		jmp .send_buffer_loop
		
.send_buffer_done
		jsr CLRCHN
		rts
