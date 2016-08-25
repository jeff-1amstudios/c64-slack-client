!zone message_screen

msg_buffer !fill 1000, 0

message_screen_enter
	; cancel screen update handler
	sei
	+set16im .update_handler, screen_update_handler_ptr
	+set16im .keyboard_handler, keyboard_handler_ptr
	cli
	jsr screen_clear
	rts

message_screen_on_data
	+set16im msg_buffer, $fb
;debugger
	jsr screen_print_str_2
	rts


; --------------------- keyboard ------------------
.keyboard_handler

.keyboard_handler_done
	jmp keyboard_handler_done

; --------------------- keyboard ------------------

.update_handler
	jmp irq_return