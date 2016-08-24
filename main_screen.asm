!zone main_screen

.str_header              !pet "Slack for Commodore64", 0
.str_header_line         !fill 40, $A3
!byte 0

visitors_buffer         !pet "waiting for data..."
!fill 235, 0

main_screen_render
	jsr screen_clear
	lda #COLOR_WHITE
	jsr CHROUT      ; foreground white

	; header row
	ldx #0         ; row
	ldy #4          ; column
	+set16im .str_header, $fb
	jsr screen_print_str

	; header row line
	ldx #1
	ldy #0
	+set16im .str_header_line, $fb
	jsr screen_print_str

	lda #COLOR_GREEN
	jsr CHROUT

	; call .update_handler on screen refresh
	sei
	+set16im .update_handler, screen_update_handler_ptr
	cli
	rts


.update_handler
	jmp irq_return
