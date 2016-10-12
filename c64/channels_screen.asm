!zone channels_screen

channel_count !byte 0
channel_entry_length !word 0
channel_selection_index !byte 0
channel_selected_line !byte 0
channel_tmp !word 0
.channel_count !byte 0
.channel_render_offset !byte 0
.mode !byte 0  ; 0 = channels, 1 = dms

.select_channel_request !text "1", 0

LIST_START_LINE = 4
LIST_LENGTH = 19

.banner_text 
    !pet "CHANNELS  /  DIRECT MESSAGES", 0

channels_screen_enter
	; cancel screen update handler
	sei
	+set16im .update_handler, screen_update_handler_ptr
	+set16im .keyboard_handler, keyboard_handler_ptr
	cli

	lda #0
	sta .mode			; channels mode by default

	jsr channels_screen_render

	jsr channels_screen_on_data
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

	; render keyboard shortcut reverse-video highlights
	lda $0400 + (2 * 40)
	eor #$80
	sta $0400 + (2 * 40)

	lda $0400 + (2 * 40) + 13
	eor #$80
	sta $0400 + (2 * 40) + 13
	; color highlights
	lda #1
	sta $d800 + (2 * 40)
	sta $d800 + (2 * 40) + 13
	rts

channels_screen_on_dm_data
	lda #1
	sta .mode
	lda #0
	sta .channel_render_offset
	sta channel_selected_line
	sta channel_selection_index
	jsr channels_screen_on_data
	rts

channels_screen_on_data
;debugger
	lda #0
	sta .channel_count
	jsr channels_screen_render

	clc
	ldx #LIST_START_LINE
	ldy #0
	jsr PLOT

	jsr .reset_channels_data_ptr

	; set CHANNELS_DATA_PTR depending on the `mode`

	ldy #2
	lda (CHANNELS_DATA_PTR), y
	sta channel_count

	+add16im CHANNELS_DATA_PTR, 3, CHANNELS_DATA_PTR  ;jump over header

	ldy #0
	sty .channel_count
	ldx #LIST_LENGTH

.channels_loop
	ldy #0
	lda (CHANNELS_DATA_PTR), y
	cmp #$ff
	beq .channels_loop_exit
	sta channel_entry_length
	+inc16 CHANNELS_DATA_PTR				; jump past 'size' field
	ldy .channel_count
	cpy .channel_render_offset
	bcc .channels_loop_skip
	ldy #9
	jsr .print_channel_name
	dex
.channels_loop_skip
	+add16 CHANNELS_DATA_PTR, channel_entry_length, CHANNELS_DATA_PTR
	inc .channel_count
	cpx #0
	bne .channels_loop
.channels_loop_exit
	jsr .toggle_selected_line
	rts

; Prints a channel name
.print_channel_name
	lda (CHANNELS_DATA_PTR), y
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
	cmp #'D'
	bne .keyboard_down_arrow
	lda #RPC_DMS_LIST
	jsr rs232_write_byte
	lda #COMMAND_TRAILER_CHAR
	jsr rs232_write_byte
	jmp .keyboard_handler_done

.keyboard_down_arrow
	cmp #KEY_DOWN
	bne .keyboard_up_arrow
	ldx channel_selected_line	; are we at the bottom of the screen?
	inx
	cpx #LIST_LENGTH
	bcs .keyboard_on_bottom_of_screen

	ldx channel_selection_index
	inx
	cpx channel_count
	beq .keyboard_on_bottom_of_list

	jsr .toggle_selected_line
	inc channel_selection_index
	inc channel_selected_line
	jsr .toggle_selected_line
	jmp .keyboard_handler_done

.keyboard_on_bottom_of_list
	jmp .keyboard_handler_done

.keyboard_on_bottom_of_screen
	ldx #0
	stx channel_selected_line
	inc channel_selection_index
	clc
	lda .channel_render_offset
	adc #LIST_LENGTH
	sta .channel_render_offset
	jsr channels_screen_on_data
	jmp .keyboard_handler_done

.keyboard_up_arrow
	cmp #KEY_UP
	bne .keyboard_return

	ldx channel_selected_line ; are we at 0th position already?
	dex
	bmi .keyboard_on_top_of_screen

	jsr .toggle_selected_line
	dec channel_selection_index
	dec channel_selected_line
	jsr .toggle_selected_line
	jmp .keyboard_handler_done	

.keyboard_on_top_of_screen
	ldx channel_selection_index	; if current_page is 0, do nothing
	beq .keyboard_handler_done

	sec
	lda .channel_render_offset
	sbc #LIST_LENGTH
	sta .channel_render_offset
	ldx #LIST_LENGTH-1
	stx channel_selected_line
	dec channel_selection_index
	jsr channels_screen_on_data

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
	lda (CHANNELS_DATA_PTR), y
	sta message_screen_channel, x
	iny
	inx
	cpy channel_entry_length
	bne .copy_channel_name_to_message_screen_loop
	lda #0
	sta message_screen_channel, x

	+set16 CHANNELS_DATA_PTR, $fb
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
	lda channel_selected_line
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
;  Returns pointer to selected channel id in CHANNELS_DATA_PTR
;
get_selected_channel
	ldy #0
	sty channel_entry_length
	jsr .reset_channels_data_ptr
	+add16im CHANNELS_DATA_PTR, 3, CHANNELS_DATA_PTR  ;jump over header
	ldx channel_selection_index
.get_selected_channel_id_loop
	+add16 CHANNELS_DATA_PTR, channel_entry_length, CHANNELS_DATA_PTR
	lda (CHANNELS_DATA_PTR), y
	sta channel_entry_length
	+inc16 CHANNELS_DATA_PTR							; jump past 'size' field
	dex
	bpl .get_selected_channel_id_loop
	rts

.reset_channels_data_ptr
	lda .mode
	bne .set_dms_ptr
	+set16im channels_buffer, CHANNELS_DATA_PTR
	rts
.set_dms_ptr
	+set16im dms_buffer, CHANNELS_DATA_PTR
	rts







