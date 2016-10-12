; !zone main_screen

; .connected_text 
; 	!pet "SLACK API ONLINE VIA RASPBERRY PI BRIDGE", 0
; .username_text !pet "Slack username:", 0

; .controls_text
; 	!pet "C - channels list", 13, 0

; .channel_list_request !text "5", 0

slack_group_count !byte 0
slack_username !fill 20, 0
slack_channels_msg !fill 30, 0

; main_screen_render
; 	jsr screen_clear

; 	ldx #TOP_BANNER_ROW
; 	ldy #TOP_BANNER_COL
; 	+set16im top_banner_text, $fb
; 	jsr screen_print_str

; 	ldx #4
; 	ldy #0
; 	+set16im .connected_text, $fb
; 	jsr screen_print_str	

; 	ldx #8
; 	ldy #0
; 	+set16im .username_text, $fb
; 	jsr screen_print_str	

; 	ldx #8
; 	ldy #15
; 	+set16im slack_username, $fb
; 	jsr screen_print_str

; 	ldx #10
; 	ldy #0
; 	+set16im .controls_text, $fb
; 	jsr screen_print_str


; 	; call .update_handler on screen refresh
; 	sei
; 	+set16im .update_handler, screen_update_handler_ptr
; 	cli

; 	lda #0
; 	sta channel_selection_index
; 	+set16im .channel_list_request, $fb
; 	jsr rs232_send_string
; 	lda #0
; 	jsr rs232_write_byte
; 	lda #COMMAND_TRAILER_CHAR
; 	jsr rs232_write_byte

; 	rts


; .update_handler
; 	jmp irq_return
