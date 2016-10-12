!zone command_handler

heartbeat_tick !byte 0

; ----------------------------------------------------------------------
; Looks at cmd_buffer and executes matching command
; ----------------------------------------------------------------------
command_handler
		lda cmd_buffer
		cmp #RPC_CHANNEL_LIST
		bne .check_msg
		+set16im cmd_buffer, $fb
		+set16im channels_buffer, $fd
		jsr string_copy
		jsr connection_screen_on_channel_data
		rts

.check_msg
		cmp #RPC_MSG_LINE
		bne .check_msg_header
		+set16im cmd_buffer, $fb
		+set16im msg_buffer, $fd
		jsr string_copy
		jsr message_screen_on_data
		rts

.check_msg_header
		cmp #RPC_MSG_LINE_HEADER
		bne .check_hello
		+set16im cmd_buffer, $fb
		+set16im msg_buffer, $fd
		jsr string_copy
		jsr message_screen_on_data
		rts

.check_hello
		cmp #RPC_HELLO
		bne .check_channels_data_info
		+set16im cmd_buffer + 1, $fb
		+set16im slack_username, $fd
		jsr string_copy
		jsr connection_screen_on_connection
		rts

.check_channels_data_info
		cmp #RPC_CHANNELS_INFO
		bne .check_dms
		+set16im cmd_buffer + 1, $fb
		+set16im slack_channels_msg, $fd
		jsr string_copy
		jsr connection_screen_on_channels_info
		rts

.check_dms
		cmp #RPC_DMS_LIST
		bne .done
		+set16im cmd_buffer, $fb
		+set16im dms_buffer, $fd
		jsr string_copy
		jsr channels_screen_on_dm_data
		rts

.done
		rts