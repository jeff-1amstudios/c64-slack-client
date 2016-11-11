!zone load_resources
.address_data = $2000  ; 8192

* = .address_data

; sprite0 - logo
!bin "resources/slack-logo.spr"


cmd_buffer !fill 2400, 0
channels_buffer !fill 2400, 0
dms_buffer !fill 1000, 0