!zone message_screen

msg_buffer !fill 1000, 0
.text !pet "[RETURN] = new message", 0

.line_count_tmp !byte 0
message_screen_channel !fill 40, 0

message_screen_enter
	; cancel screen update handler
	sei
	+set16im .update_handler, screen_update_handler_ptr
	+set16im .keyboard_handler, keyboard_handler_ptr
	cli
	jsr screen_clear

	ldx #TOP_BANNER_ROW
	ldy #TOP_BANNER_COL
	+set16im top_banner_text, $fb
	jsr screen_print_str

	ldx #0
	ldy #0
	+set16im message_screen_channel, $fb
	jsr screen_print_str

	ldx #24
	ldy #0
	+set16im .text, $fb
	jsr screen_print_str
	rts

message_screen_on_data
	;jsr keyboard_wait
	lda msg_buffer
	sta .line_count_tmp
.scroll_up_loop
	lda #2
	ldy #21
	jsr screen_scroll_lines_up

	dec msg_buffer
	bpl .scroll_up_loop

	+set16im msg_buffer+1, $fb
	lda #21
	sec
	sbc .line_count_tmp
	tax
	ldy #0
;debugger
	jsr screen_print_str
	rts


; --------------------- keyboard ------------------
.keyboard_handler

.keyboard_handler_done
	jmp keyboard_handler_done

; --------------------- keyboard ------------------

.update_handler
	jmp irq_return