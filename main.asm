!cpu 6510
!to "./build/ms4.prg",cbm
!zone main
!source "macros.asm"


BASIC_START = $0801
CODE_START = $9000

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
.dbg_pos !byte 0

init
	; disable BASIC rom
	lda $01
	and #%11111110
	sta $01

	jsr screen_clear
	jsr screen_enable_lowercase_chars

	jsr rs232_open
	jsr message_screen_init
	jsr wait_for_connection_screen_render
	jsr irq_init

	+set16im cmd_buffer, COMMAND_BUFFER_PTR

.main_loop
	jsr keyboard_read
	jsr rs232_try_read_byte
	cmp #0
	beq .main_loop

	sta $0400 + (40 * 23) + 38

	cmp #126        ; tilde char means 'end of command'
	bne .add_byte_to_buffer
	ldy #1          ; if tilde, then set Y = 1
	sty .end_of_command
	lda #0          ; replace ~ with \0 so we write the end of the string
add_byte
.add_byte_to_buffer

	ldy #0
	sta (COMMAND_BUFFER_PTR), y
	+inc16 COMMAND_BUFFER_PTR

	ldy .end_of_command
	cpy #1          ; if not 'end of command', go back around
	bne .main_loop
	lda #$20
	sta $0400 + (40 * 23) + 38
	jsr command_handler
	+set16im cmd_buffer, COMMAND_BUFFER_PTR
	ldx #0
	stx .end_of_command
;debugger
	jmp .main_loop

cmd_buffer !fill 1200, 0
.end_of_command !byte 0
.debug_output_offset !byte 0

.print_output
	clc
	ldx #24
	ldy #38
	jsr PLOT
	jsr CHROUT


!source "defs.asm"
!source "screen.asm"
!source "rs232.asm"
!source "wait_for_connection_screen.asm"
!source "main_screen.asm"
!source "channels_screen.asm"
!source "message_screen.asm"
!source "string.asm"
!source "cmd_handler.asm"
!source "keyboard_input.asm"
!source "irq.asm"
!source "heartbeat.asm"
!source "memory.asm"
!source "shared_resources.asm"
!source "math.asm"
!source "logo_sprite.asm"

;!if * > $9fff {
;	!error "Program reached ROM: ", * - $d000, " bytes overlap."
;}
