!zone tweet_screen
.str_tweet_banner
!pet "    #mulesoft-connects-everything", 13, 13
!pet "        #c64       #mulesoftLobby", 13, 13, 13, 13
!pet "Tweet from our internet-connected 1985              Commodore64:", 13, 13
!byte 0
.str_sending !pet "Sending data to event ingest API...", 0
.str_complete !pet "Complete. Hit any key to continue.", 0
.tweet_buffer !fill 140, 0

tweet_screen_render
	jsr screen_clear

	; call .update_handler on screen refresh
	sei
	+set16im .update_handler, screen_update_handler_ptr
	cli
	
	lda #COLOR_WHITE
	jsr CHROUT      ; foreground white

	ldx #5
	ldy #0		
	+set16im .str_tweet_banner, $fb
	jsr screen_print_str

	jsr twitter_sprite_init

	lda #155
	sta $d002
	lda #50
	sta $d003

	ldx #14
	ldy #0
	clc
	jsr PLOT

	ldy #0
.read_keyboard_input
	jsr CHRIN	; read line from keyboard (first call), 
			; subsequent calls will retrieve each byte of that input
	sta .tweet_buffer, y
	iny
	cmp #13
	bne .read_keyboard_input
	lda #0		; write a \0 at end of input
	sta .tweet_buffer, y

	tya
	cmp #2
check_tweet_2
	beq .no_data_entered

	ldx #18
	ldy #0
	+set16im .str_sending, $fb
	jsr screen_print_str

	+set16im .str_complete, $fb
	ldx #20
	ldy #0
	jsr screen_print_str

	+set16im .tweet_buffer, $fb

	lda #'1'	; cmd-type
	jsr rs232_write_byte
	jsr rs232_send_string
	lda #'~'	; cmd-trailer
	jsr rs232_write_byte

	jsr keyboard_wait

.no_data_entered
	rts

.update_handler
	jsr twitter_sprite_update
	jmp irq_return

	


