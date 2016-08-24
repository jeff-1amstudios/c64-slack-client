!zone load_resources
.address_sprites = $2000  ; 8192

* = .address_sprites                  

!bin "resources/mule.spr"  ; (512)

;!warn "Program reached ROM2x: ", *

; 8704
!bin "resources/roller.spr" ;(512)

; 9216
!bin "resources/waving_hand.spr" ; (704)

; 9920
!bin "resources/jackson.spr" ; (4416)

; 14336
!bin "resources/smiler.spr", 1024 ; (1024)

; 15360
!bin "resources/twitter.spr" ; (512)

; 15872
!bin "resources/weather.spr" ; (512)


logo_data
!bin "resources/logo.bin"


; sprite0 - mule, jackson
; sprite1 - twitter
; sprite2 - roller
; sprite3 - left hand
; sprite4 - right hand
; sprite5 - weather
; sprite6 - smiler
; sprite7 - 


