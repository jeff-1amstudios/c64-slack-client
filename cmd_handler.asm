!zone command_handler

CMD_CHANNELS = "0"
CMD_MSG_LINE = "1"
CMD_HELLO = "2"
CMD_MSG_HEADER = "3"

heartbeat_tick !byte 0

; ----------------------------------------------------------------------
; Looks at cmd_buffer and executes matching command
; ----------------------------------------------------------------------
command_handler
		lda cmd_buffer
		cmp #CMD_CHANNELS
		bne .check_msg
		+set16im cmd_buffer, $fb
		+set16im channels_buffer, $fd
		jsr mem_copy
		jsr channels_screen_on_data
		rts

.check_msg
		cmp #CMD_MSG_LINE
		bne .check_msg_header
		+set16im cmd_buffer, $fb
		+set16im msg_buffer, $fd
		jsr string_copy
		jsr message_screen_on_data
		rts

.check_msg_header
		cmp #CMD_MSG_HEADER
		bne .check_hello
		+set16im cmd_buffer, $fb
		+set16im msg_buffer, $fd
		jsr string_copy
		jsr message_screen_on_data
		rts

.check_hello
		cmp #CMD_HELLO
		bne .done
		+set16im cmd_buffer + 1, $fb
		+set16im slack_username, $fd
		jsr string_copy
		jsr main_screen_render

.done
		rts