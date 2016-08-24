!zone channels_screen

channels_buffer !fill 1000, 0
channels_buffer_ptr !word 0
channel_len !word 0
channel_count !byte 0
channel_selection_index !byte 0
channel_tmp !word 0
.channels_request !text "channels.list~", 0

channels_screen_enter
	; cancel screen update handler
	sei
	+set16im .update_handler, screen_update_handler_ptr
	+set16im .keyboard_handler, keyboard_handler_ptr
	cli

	jsr screen_clear
	+set16im .channels_request, $fb
	jsr rs232_send_string
	rts

channels_screen_on_data
	ldx channels_buffer  ; nbr of channels
	stx channel_count
	ldy #0
	+set16im channels_buffer+1, $fb

.channels_loop
	ldy #11
	jsr .print_channel_name
	sty channel_len
	+add16 $fb, channel_len, $fb
	dex
	bne .channels_loop

	jsr .toggle_selected_line
	rts

; Prints a channel name
.print_channel_name
	lda ($fb), y
	cmp #':'
	beq .print_channel_exit
	jsr CHROUT
	iny
	bne .print_channel_name
.print_channel_exit
	lda #13
	jsr CHROUT
	rts

.keyboard_handler
	cmp #$11 					; down arrow 
	bne .keyboard_up_arrow

	ldx channel_selection_index	; are we already at the end of our channel list?
	inx
	cpx channel_count
	bcs .keyboard_handler_done

	jsr .toggle_selected_line
	inc channel_selection_index
	jsr .toggle_selected_line
	jmp .keyboard_handler_done

.keyboard_up_arrow
	cmp #$91 					; up arrow
	bne .keyboard_space

	lda channel_selection_index ; are we at 0th position already?
	beq .keyboard_handler_done	

	jsr .toggle_selected_line
	dec channel_selection_index
	jsr .toggle_selected_line
	jmp .keyboard_handler_done	

.keyboard_space
	cmp #$20
	bne .keyboard_handler_done


.keyboard_handler_done
	jmp keyboard_handler_done

.update_handler
	jmp irq_return

.toggle_selected_line
	ldx channel_selection_index
	lda #40
	jsr multiply
	stx channel_tmp
	sta channel_tmp + 1
	+add16im channel_tmp, $0400, $02
	ldy #39
.toggle_char
	lda ($02), y
	eor #$80 		; toggle reverse chars
	sta ($02), y
	dey
	bpl .toggle_char
	rts

	; name:   8 bit multiplication, written by Damon Slye
; call:   accu: multiplier
;     x-register: multiplicant
; return: product in accu (hibyte) and x-register (lowbyte)

multiplier  = $02           ; some zeropage adress

multiply
        cpx #$00
        beq multiply_end
        dex
        stx multiply_mod+1
        lsr
        sta multiplier
        lda #$00
        ldx #$08
multiply_loop        bcc multiply_skip
multiply_mod     adc #$00
multiply_skip        ror
        ror multiplier
        dex
        bne multiply_loop
        ldx multiplier
        rts
multiply_end     
        txa
        rts




