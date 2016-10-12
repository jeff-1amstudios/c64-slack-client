!zone load_resources
.address_data = $2000  ; 8192

* = .address_data

!bin "resources/slack-logo.spr"

; sprite0 - logo
; sprite1 - 
; sprite2 - 
; sprite3 - 
; sprite4 - 
; sprite5 - 
; sprite6 - 
; sprite7 - 

LINES_BUFFER_SIZE = 255
message_lines_render_start_index !byte 0
message_lines_next_insert_index !byte 0
message_lines_pointers_lo !fill LINES_BUFFER_SIZE
message_lines_pointers_hi !fill LINES_BUFFER_SIZE
message_lines_buffer !fill 42 * LINES_BUFFER_SIZE, 0

channels_buffer !fill 1600, 0
dms_buffer !fill 500, 0