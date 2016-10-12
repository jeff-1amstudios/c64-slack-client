!zone macros
; Constants
SYSTEM_IRQ_VECTOR = $314


!macro set16im .value, .dest {                                   ; store a 16bit constant to a memory location
    lda #<.value
    sta .dest
    lda #>.value
    sta .dest+1
}

!macro set16 .value, .dest {                                     ; copy a 16bit memory location to dest
    lda .value
    sta .dest
    lda .value+1
    sta .dest+1
}

!macro inc16 .n1 {
    inc .n1                                                      ; Increment the LSB
    bne .done                                                    ; If the result was not zero we're done
    inc .n1+1                                                    ; Increment the MSB if LSB wrapped round
.done   
}

; n1 = memory location
; n2 = constant
; result = store
!macro add16im .n1, .n2, .result {                               ; add a 16bit constant to a memory location, store in result
    clc                                                          ; ensure carry is clear
    lda .n1                                                    ; add the two least significant bytes
    adc #<.n2
    sta .result                                                
    lda .n1+1                                                    ; add the two most significant bytes
    adc #>.n2                                                    
    sta .result+1                                                
}

!macro sub16im .n1, .n2, .result {                               ; subtract a 16bit constant to a memory location, store in result
    sec                                                          ; ensure carry is clear
    lda .n1+0                                                    ; add the two least significant bytes
    sbc #<.n2
    sta .result+0                                                
    lda .n1+1                                                    ; add the two most significant bytes
    sbc #>.n2                                                    
    sta .result+1                                                
}

!macro add16 .n1, .n2, .result {                                 ; add 2 16bit memory locations, store in result
    clc             
    lda .n1       
    adc .n2
    sta .result+0
    lda .n1+1       
    adc .n2+1       
    sta .result+1
}



!macro set_raster_interrupt .line, .handler {
    sei                                                          ; disable interrupts
    lda #.line
    sta $d012                                                    ; this is the raster line register
    +set16im .handler, SYSTEM_IRQ_VECTOR                         ; set system IRQ vector to our handler
    cli                                                          ; enable interrupts
}

!macro disable_x_scroll {                                        ; set horizontal softscroll value to 0
    lda $d016
    and #$F8
    sta $d016
}

!macro update_x_scroll .xvalue {                                 ; set horizontal softscroll value to xvalue
    lda $d016
    and #$F8
    clc
    adc .xvalue
    sta $d016
}

!macro debug_print .value, .column {                             ; put a char in the bottom line of the screen
    lda .value
    clc
    adc #$30
    sta $0400+40*24+.column
    sta $0800+40*24+.column
    lda #1
    sta $d800+40*24+.column
}