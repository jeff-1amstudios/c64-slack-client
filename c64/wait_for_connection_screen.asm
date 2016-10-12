!zone wait_for_connection_screen

.banner 
	!pet "        CONNECTING TO SLACK API", 13
	!pet "  VIA RASPBERRY PI SERIAL PORT PROXY", 0

.wait_text 
	!pet "WAITING FOR SERIAL PORT HANDSHAKE...", 0
.username_label
	!pet "> CONNECTED AS", 0

.load_data_text 
	!pet "RECEIVING CHANNEL DATA...", 0

.press_key_to_continue_text
	!pet "PRESS ANY KEY TO CONTINUE", 0

.text_flash !byte 30
.color_switch_index !byte 0
.color_switch_table !byte 1, 30
connection_handshake_status !byte 0

wait_for_connection_screen_render
	sei
	+set16im .update_handler, screen_update_handler_ptr
	;+set16im .keyboard_handler, keyboard_handler_ptr
	cli

	jsr screen_clear
	
	ldx #TOP_BANNER_ROW
	ldy #TOP_BANNER_COL
	+set16im top_banner_text, $fb
	jsr screen_print_str

	ldx #4
	ldy #0
	+set16im .banner, $fb
	jsr screen_print_str

	ldx #10
	ldy #2
	+set16im .wait_text, $fb
	jsr screen_print_str

	jsr logo_sprite_init
	rts

.update_handler
	jsr logo_sprite_update
	dec .text_flash
	bne .skip_color_change

	lda #30
	sta .text_flash

	lda .color_switch_index
	eor #1
	sta .color_switch_index
	ldx .color_switch_index
	lda .color_switch_table, x
	ldx #80
.update_color_loop
	ldy connection_handshake_status
	cpy #0
	bne .do_press_key_line
	sta $d800 + (40*4), x
	jmp .decx
.do_press_key_line	
	sta $d800 + (40*20), x
.decx
	dex
	bpl .update_color_loop

.skip_color_change
	jmp irq_return

connection_screen_on_connection	
	clc
	ldx #10
	ldy #0
	jsr PLOT
	lda #COLOR_GREEN
	jsr CHROUT
	lda #$fa ; tickmark
	jsr CHROUT
	lda #COLOR_LIGHT_BLUE
	jsr CHROUT

	ldx #11
	ldy #4
	+set16im .username_label, $fb
	jsr screen_print_str

	lda #COLOR_GREEN
	jsr CHROUT
	ldx #11
	ldy #19
	+set16im slack_username, $fb
	jsr screen_print_str

	lda #COLOR_LIGHT_BLUE
	jsr CHROUT

	ldx #14
	ldy #2
	+set16im .load_data_text, $fb
	jsr screen_print_str

	lda #RPC_CHANNEL_LIST
	jsr rs232_write_byte
	lda #COMMAND_TRAILER_CHAR
	jsr rs232_write_byte
	rts

connection_screen_on_channels_info
	lda #COLOR_GREEN
	jsr CHROUT
	ldx #15
	ldy #4
	+set16im slack_channels_msg, $fb
	jsr screen_print_str

	lda #COLOR_LIGHT_BLUE
	jsr CHROUT
	rts

connection_screen_on_channel_data
	lda #1
	sta connection_handshake_status
	clc
	ldx #14
	ldy #0
	jsr PLOT
	lda #COLOR_GREEN
	jsr CHROUT
	lda #$fa ; tickmark
	jsr CHROUT
	lda #COLOR_LIGHT_BLUE
	jsr CHROUT

	jsr logo_sprite_disable

	ldx #20
	ldy #8
	+set16im .press_key_to_continue_text, $fb
	jsr screen_print_str

	jsr keyboard_wait
	jsr channels_screen_enter
	rts
	
