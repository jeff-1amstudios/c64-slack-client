!zone channels_screen

channels_buffer !fill 1200, 0
channels_buffer_ptr !word 0
channel_len !word 0
channel_count !byte 0
channel_entry_length !word 0
channel_selection_index !byte 0
channel_tmp !word 0
channel_current_page !byte 0
channel_page_count !byte 0
.channel_list_request !text "0", 0
.select_channel_request !text "1", 0

LIST_START_LINE = 4

.banner_text 
    !pet "   CHANNELS:  ", 0

channels_screen_enter
	; cancel screen update handler
	sei
	+set16im .update_handler, screen_update_handler_ptr
	+set16im .keyboard_handler, keyboard_handler_ptr
	cli

	jsr channels_screen_render

	jsr channels_screen_send_request
	rts

channels_screen_render
	jsr screen_clear

	ldx #TOP_BANNER_ROW
	ldy #TOP_BANNER_COL
	+set16im top_banner_text, $fb
	jsr screen_print_str

	ldx #2
	ldy #0
	+set16im .banner_text, $fb
	jsr screen_print_str
	rts

channels_screen_send_request
	lda #0
	sta channel_selection_index
	+set16im .channel_list_request, $fb
	jsr rs232_send_string
	lda channel_current_page
	jsr rs232_write_byte
	lda #COMMAND_TRAILER_CHAR
	jsr rs232_write_byte
	rts

channels_screen_on_data
	jsr channels_screen_render

	clc
	ldx #LIST_START_LINE
	ldy #0
	jsr PLOT

	ldx channels_buffer + 1
	stx channel_page_count
	ldx channels_buffer + 2
	stx channel_count
	+set16im channels_buffer+3, $fb

.channels_loop
	ldy #0
	lda ($fb), y
	sta channel_entry_length
	+inc16 $fb 								; jump past 'size' field
	ldy #9
	jsr .print_channel_name
	+add16 $fb, channel_entry_length, $fb
	dex
	bne .channels_loop
	jsr .toggle_selected_line
	rts

; Prints a channel name
.print_channel_name
	lda ($fb), y
	jsr CHROUT
	iny
	cpy channel_entry_length
	beq .print_channel_exit
	jmp .print_channel_name
.print_channel_exit
	lda #13
	jsr CHROUT
	rts

; --------------------- keyboard ------------------
.keyboard_handler
	cmp #KEY_DOWN
	bne .keyboard_up_arrow

	ldx channel_selection_index	; are we already at the end of our channel list?
	inx
	cpx channel_count
	bcs .keyboard_on_bottom_of_screen

	jsr .toggle_selected_line
	inc channel_selection_index
	jsr .toggle_selected_line
	jmp .keyboard_handler_done

.keyboard_on_bottom_of_screen
	ldx channel_current_page	; if increasing current_page would == page_count, ignore
	inx
	cpx channel_page_count
	beq .keyboard_handler_done
	inc channel_current_page
	jsr channels_screen_send_request
	jmp .keyboard_handler_done

.keyboard_up_arrow
	cmp #KEY_UP
	bne .keyboard_return

	ldx channel_selection_index ; are we at 0th position already?
	dex
;debugger
	bmi .keyboard_on_top_of_screen

	jsr .toggle_selected_line
	dec channel_selection_index
	jsr .toggle_selected_line
	jmp .keyboard_handler_done	

.keyboard_on_top_of_screen
	ldx channel_current_page	; if increasing current_page would == page_count, ignore
	beq .keyboard_handler_done
	dec channel_current_page
	jsr channels_screen_send_request
	jmp .keyboard_handler_done

.keyboard_return
	cmp #13
	bne .keyboard_handler_done
	+set16im .select_channel_request, $fb
	jsr rs232_send_string
	jsr get_selected_channel
	
	ldy #9
	ldx #0
.copy_channel_name_to_message_screen_loop
	lda ($fb), y
	sta message_screen_channel, x
	iny
	inx
	cpy channel_entry_length
	bne .copy_channel_name_to_message_screen_loop

	lda #9						
	jsr rs232_send_buffer
	lda #COMMAND_TRAILER_CHAR
	jsr rs232_write_byte
	jsr message_screen_enter


.keyboard_handler_done
	jmp keyboard_handler_done

; --------------------- keyboard ------------------

.update_handler
	jmp irq_return

.toggle_selected_line
	lda channel_selection_index
	clc
	adc #LIST_START_LINE
	ldx #40
	jsr multiply
	stx channel_tmp
	sta channel_tmp + 1
	+add16im channel_tmp, $0400, ZP_TMP_1
	ldy #39
.toggle_char
	lda (ZP_TMP_1), y
	eor #$80 		; toggle reverse chars
	sta (ZP_TMP_1), y
	dey
	bpl .toggle_char
	rts

;
;  Returns pointer to selected channel id in $fb
;
get_selected_channel
	ldy #0
	sty channel_entry_length
	+set16im channels_buffer+3, $fb
	ldx channel_selection_index
.get_selected_channel_id_loop
	+add16 $fb, channel_entry_length, $fb
	lda ($fb), y
	sta channel_entry_length
	+inc16 $fb 								; jump past 'size' field
	dex
	bpl .get_selected_channel_id_loop
	rts







