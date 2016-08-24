!zone command_handler

CMD_CHANNELS = "0"

heartbeat_tick !byte 0

; ----------------------------------------------------------------------
; Looks at cmd_buffer and executes matching command
; ----------------------------------------------------------------------
command_handler
		lda cmd_buffer
		cmp #CMD_CHANNELS
		bne .done
		+set16im cmd_buffer + 1, $fb
		+set16im channels_buffer, $fd
		jsr string_copy
		jsr channels_screen_on_data
		rts
.done
		rts