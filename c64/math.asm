; name:   8 bit multiplication, written by Damon Slye
; call:   accu: multiplier
;     x-register: multiplicant
; return: product in accu (hibyte) and x-register (lowbyte)

multiply
        cpx #$00
        beq multiply_end
        dex
        stx multiply_mod+1
        lsr
        sta ZP_TMP_1
        lda #$00
        ldx #$08
multiply_loop        bcc multiply_skip
multiply_mod     adc #$00
multiply_skip        ror
        ror ZP_TMP_1
        dex
        bne multiply_loop
        ldx ZP_TMP_1
        rts
multiply_end     
        txa
        rts