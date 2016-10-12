!zone gif_sprite

.FRAME_COUNT = 43
.ANIM_DELAY = 3
.SPRITE_0_PTR = 128

.DISPLAY_X = 65
.DISPLAY_Y = 225

.frame_counter !byte .FRAME_COUNT
.anim_delay !byte .ANIM_DELAY

logo_sprite_init
	lda #.SPRITE_0_PTR
	sta $07f8
	
	lda $d015
	ora #%00000001		; enable sprite 0
	sta $d015
	lda #1
	sta $d027			; sprite color
	
	; sprite #0 (top-left)
	lda #.DISPLAY_X
	sta $d000		; x
	lda #.DISPLAY_Y
	sta $d001		; y

	lda #1			; enable 9th bit of X position (255 + x)
	sta $d010

	lda $d01d
	ora #%00000001
	;sta $d01d		; enable sprite 0 x-expand
	lda $d017
	ora #%00000001
	;sta $d017		; enable sprite 0 y-expand
	rts


logo_sprite_update
	dec .anim_delay
	bne .done
	ldx #.ANIM_DELAY
	stx .anim_delay
	dec .frame_counter
	bne .update_frame
	lda #.SPRITE_0_PTR
	sta $07f8
	ldx #.FRAME_COUNT
	stx .frame_counter
	rts
.update_frame
	;inc $d027
	inc $07f8

.done
	rts

logo_sprite_disable
	lda $d015
	and #%11111110		; disable sprite 0
	sta $d015
	rts


	
