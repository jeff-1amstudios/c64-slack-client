!zone keyboard_input

;up $91
; left 9d
; down $11
; right $1d
keyboard_read
		jsr GETIN
		cmp #0
		bne .check_input
		rts

.check_input
		cmp #'C'
		bne .run_custom_handler
		jsr channels_screen_enter
		rts

.run_custom_handler
		ldx keyboard_handler_ptr
		beq keyboard_handler_done
		jmp (keyboard_handler_ptr)

keyboard_handler_done
		rts

keyboard_wait
		jsr GETIN
		cmp #0
		beq keyboard_wait
		rts