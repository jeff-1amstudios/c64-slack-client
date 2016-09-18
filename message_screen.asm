!zone message_screen

msg_buffer !fill 42, 0
.str_line         
	!byte COLOR_BLACK
	!fill 40, $A4
	!byte COLOR_LIGHT_BLUE
.text !pet "RETURN to message the channel", 0

.line_count_tmp !byte 0
message_screen_channel !fill 40, 0
.new_message_buffer !fill 255, 0
.message_list_offset !byte 0

.tmp !word 0

message_screen_init
	ldx #0
	+set16im message_lines_buffer, .tmp
.loop
	lda .tmp
	sta message_lines_pointers_lo, x
	lda .tmp+1
	sta message_lines_pointers_hi, x
	inx
	+add16im .tmp, 42, .tmp
	cpx #LINES_BUFFER_SIZE
	bne .loop
	rts
	

message_screen_enter
	; cancel screen update handler
	sei
	+set16im .update_handler, screen_update_handler_ptr
	+set16im .keyboard_handler, keyboard_handler_ptr
	cli
	jsr message_screen_render

message_screen_render
	jsr screen_clear

	ldx #TOP_BANNER_ROW
	ldy #TOP_BANNER_COL
	+set16im top_banner_text, $fb
	jsr screen_print_str

	ldx #0
	ldy #0
	+set16im message_screen_channel, $fb
	jsr screen_print_str

	ldx #22
	ldy #0
	+set16im .str_line, $fb
	jsr screen_print_str

	ldx #23
	ldy #0
	+set16im .text, $fb
	jsr screen_print_str
	rts


message_screen_on_data
	ldx message_lines_next_insert_index
	lda message_lines_pointers_lo, x
	sta $fd
	lda message_lines_pointers_hi, x
	sta $fe

	+set16im msg_buffer, $fb
	jsr string_copy

	; increment message_lines_next_insert_index, wrapping at LINES_BUFFER_SIZE
	inc message_lines_next_insert_index
	lda message_lines_next_insert_index
	and #LINES_BUFFER_SIZE
	sta message_lines_next_insert_index
	sta .message_list_offset

	+set16im msg_buffer, $fb
	jsr append_message_to_screen
	rts

;
; $fb/$fc pointer to message string
;
append_message_to_screen
	ldy #0
	lda ($fb), y
	beq .append_message_to_screen_done

	lda #3
	ldy #18
	jsr screen_scroll_lines_up

	ldy #0
	lda ($fb), y
	cmp #'3'
	bne .render_text
	lda #COLOR_GREEN
	jsr CHROUT
.render_text
	+inc16 $fb  ; jump over 'type' field
	ldx #20
	ldy #0
	jsr screen_print_str

	lda #COLOR_LIGHT_BLUE
	jsr CHROUT

.append_message_to_screen_done
	rts

; --------------------- keyboard ------------------
.keyboard_handler
	cmp #13
	bne .check_up
	jsr .read_message_input_from_keyboard
	jmp .keyboard_handler_done
.check_up
	cmp #KEY_UP
	bne .check_down
	inc $d020
	dec .message_list_offset
	;jsr .print_message_list
	jmp .keyboard_handler_done
.check_down
	cmp #KEY_DOWN
	bne .keyboard_handler_done
	inc .message_list_offset
	;jsr .print_message_list
	jmp .keyboard_handler_done

.keyboard_handler_done
	jmp keyboard_handler_done

; --------------------- keyboard ------------------

.update_handler
	jmp irq_return

.read_message_input_from_keyboard
	ldx #80						; clear the input area
	lda #$20
.clear_input_area
	sta $0400 + (40 * 23), x
	dex
	bpl .clear_input_area

	clc
	ldx #23
	ldy #0
	jsr PLOT
.read_input
	jsr CHRIN	; read line from keyboard (first call), 
			; subsequent calls will retrieve each byte of that input
	sta .new_message_buffer, y
	iny
	cmp #13
	bne .read_input
	lda #126		; write a \0 at end of input
	sta .new_message_buffer, y


	;jsr message_screen_render
	;jsr .print_message_list
	rts

; .print_message_list
; 	lda #3
; 	sta .line_count_tmp
; 	lda .message_list_offset
; 	sec
; 	sbc #19
; 	sta .tmp
; 	tax
; .msg_render_loop
; 	lda message_lines_pointers_lo, x
; 	sta $fb
; 	lda message_lines_pointers_hi, x
; 	sta $fc
; 	jsr message_screen_render_msg
; 	inc .line_count_tmp
; 	ldx .line_count_tmp
; 	ldy #0
; 	clc
; 	jsr PLOT
; 	inc .tmp
; 	ldx .tmp
; 	cpx .message_list_offset
; 	bne .msg_render_loop
; 	rts