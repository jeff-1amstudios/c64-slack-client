!zone wait_for_connection_screen

.wait_text 
	!pet "    Waiting for connection attempt ", 13
	!pet "        from Raspberry Pi...", 0
.text_flash !byte 30
.text_color !byte 1

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

	ldx #10
	ldy #0
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

	lda .text_color
	eor #1
	sta .text_color
	ldx #80
.update_color_loop
	sta $d800 + (40*10), x
	dex
	bpl .update_color_loop

.skip_color_change
	jmp irq_return