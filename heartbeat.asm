!zone heartbeat

.frame_counter !byte 60
.str_heartbeat !text "hb~", 0

heartbeat_reset
		lda #255
		sta .frame_counter
		rts

heartbeat_frame_counter
		dec .frame_counter
		bne .done

		+set16im .str_heartbeat, $fb
		jsr rs232_send_string
		jsr heartbeat_reset
		jsr render_heartbeat
.done
		rts

render_heartbeat
		ldx #0
		ldy #39
		clc
		jsr PLOT
		lda heartbeat_tick
		eor #1
		sta heartbeat_tick
		bne .test_heartbeat_print_tick
		lda #COLOR_WHITE
		jsr CHROUT
		lda #32                 ; print " "
		jsr CHROUT
		rts
.test_heartbeat_print_tick
		lda #COLOR_WHITE
		jsr CHROUT
		lda #186                ; print "{tick}"
		jsr CHROUT
		rts

