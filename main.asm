!cpu 6510
!to "./build/ms4.prg",cbm
!zone main
!source "macros.asm"


BASIC_START = $0801
CODE_START = $8000

* = BASIC_START
!byte 12,8,0,0,158
!if CODE_START >= 10000 {!byte 48+((CODE_START/10000)%10)}
!if CODE_START >= 1000 {!byte 48+((CODE_START/1000)%10)}
!if CODE_START >= 100 {!byte 48+((CODE_START/100)%10)}
!if CODE_START >= 10 {!byte 48+((CODE_START/10)%10)}
!byte 48+(CODE_START % 10),0,0,0

; load resources into memory
!source "load_resources.asm"


* = CODE_START
	jmp init


screen_update_handler_ptr !word 0
keyboard_handler_ptr !word 0

init
	; disable BASIC rom
	lda $01
	and #%01111111
	sta $01

	jsr screen_clear
	jsr screen_enable_lowercase_chars

	jsr rs232_open
	jsr main_screen_render
	jsr irq_init

.main_loop
	jsr keyboard_read
	jsr rs232_try_read_byte
	cmp #0
	beq .main_loop  

	ldy #0          ; reset our 'end of command' marker
	cmp #126        ; tilde char means 'end of command'
	bne .add_byte_to_buffer
	ldy #1          ; if tilde, then set Y = 1
	sty .end_of_command
	lda #0          ; replace ~ with \0 so we write the end of the string
.add_byte_to_buffer
	;inc $d020
	ldx cmd_buffer_ptr
	sta cmd_buffer, x
	inc cmd_buffer_ptr

	;jsr heartbeat_reset

	ldy .end_of_command
	cpy #1          ; if not 'end of command', go back around
	bne .main_loop

	jsr command_handler
	ldx #0                  ; set length of buffer back to zero
	stx cmd_buffer_ptr
	stx .end_of_command
	jmp .main_loop

cmd_buffer !fill 250, 0
cmd_buffer_ptr !byte 0
.end_of_command !byte 0


!source "defs.asm"
!source "screen.asm"
!source "rs232.asm"
!source "main_screen.asm"
!source "channels_screen.asm"
!source "string.asm"
!source "cmd_handler.asm"
!source "keyboard_input.asm"
!source "irq.asm"
!source "heartbeat.asm"

!if * > $9fff {
	!error "Program reached ROM: ", * - $d000, " bytes overlap."
}
