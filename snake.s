;------------------------------------------------
;stale z adresami zmiennych strony zerowej

scraddr = $0002 ;wskazniki do roznych miejsc w
coladdr = $0004 ;pamieci kolorow i ekranowej
                ;na uzytek roznych funkcji

lvladdr = $0006 ;adres na uzytek funkcji loadlvl

;adresy/wspolrzedne glowy i ogona weza
;(w pamieci ekranowej)
snakebegin = $0008
snakeend = $000a

tongueaddr = $000c ;wspolrzedne jezyczka weza

;------------------------------------------------
;adresy leveli

level0 = $3000

;maksymalny level (licząc od 0)
maxlevel = 7

;------------------------------------------------
;stale z kodami ekranowymi znakow
;patrz tez sekcja *=$2200

headup = 64
headdown = 65
headleft = 66
headright = 67

bodyvert = 68
bodyhoriz = 69

turnleftup = 70
turnupright = 71
turnleftdown = 72
turndownright = 73

tailup = 74
taildown = 75
tailleft = 76
tailright = 77

tongueup = 78
tonguedown = 79
tongueleft = 80
tongueright = 81

wallupleft = 82
wallupright = 83
walldownleft = 84
walldownright = 85

candy = 86
cherry = 87
lemon = 88
apple = 89

;------------------------------------------------
;------------------------------------------------

    *=$801
basicstart
    .byte $0C,$08,$0A,$00,$9E,$20,$32,$30,$36,$34,$00,$00,$00
    
;------------------------------------------------
;------------------------------------------------

    *=$810
    .offs $810-*
    
init
    lda #0
    sta $d021 ;ekran na czarno
    sta $d020 ;obramowanie tez
    
    jsr initcharset
    jsr initsnd
    
reset
    jsr clrscr
    
    jsr titlescreen

    lda #$00
    sta score
    sta score+1
    sta score+2
    
    lda #$00
    sta curlvl
    
    jsr loadlvl
    jsr drawscore
    
;glowna petla
mainloop
    jsr chklvlpts ;spr awans na wyzszy poziom

    lda pauseflag ;spr czy pauza
    cmp #0
    beq *+10
    jsr waitjoydir ;kierunek na joysticku
    lda #0          ;wylacza pauze
    sta pauseflag

    lda #$10
    jsr wait
    jsr readjoy
    lda #$10
    jsr wait
    jsr readjoy
    lda #$10
    jsr wait
    jsr readjoy
    lda #$10
    jsr wait
    jsr readjoy
    
    jsr advsnake
    
    lda #$10
    jsr wait
    jsr readjoy
    lda #$10
    jsr wait
    jsr readjoy
    
    jsr silent
    
    jmp mainloop

    rts

;------------------------------------------------
;ekran tytułowy

titlescreen
.block
    lda #titleupleft/64
    sta 2040
    lda #titleupright/64
    sta 2041
    lda #titledownleft/64
    sta 2042
    lda #titledownright/64
    sta 2043
    lda #titletongue0/64
    sta 2044
    
    ;kolory trybu multicolor
    lda #8
    sta $d025
    lda #9
    sta $d026
    
    ;kolory indywidualne
    lda #1
    sta $d027
    sta $d028
    sta $d029
    sta $d02a
    lda #2
    sta $d02b
    
    ;wspolrzedne
    ldx #136
    ldy #70
    stx $d000
    sty $d001
    ldx #184
    stx $d002
    sty $d003
    ldx #136
    ldy #112
    stx $d004
    sty $d005
    ldx #184
    stx $d006
    sty $d007
    ldx #98 ;jezyczek
    ldy #133
    stx $d008
    sty $d009
    
    ;podwoić szerokosc i wysokosc spritow
    lda #$1f
    sta $d017
    sta $d01d
    
    lda #$1f
    sta $d01c ;wlaczyc multicolor
    sta $d015 ;wlaczyc sprity
    
    jsr drawscore
    
    ldx #0
str1loop
    lda gamenamestr,x
    sta 1024+(13*40)+13,x
    inx
    cpx #14
    bne str1loop
    
    ldx #0
str3loop
    lda authorstr,x
    sta 2024-34,x
    inx
    cpx #28
    bne str3loop
    
titleloop ;glowna petla tego ekranu
    ;animacja wezowego jezyka
    lda 2044
    cmp #titletongue3/64
    bne *+10
    lda #titletongue0/64
    sta 2044
    jmp sprend
    inc 2044
sprend

    ;migajacy napis press fire
    lda blinkflag
    cmp #0
    bne drawstr2
    ldx #0
    lda #0
nostr2loop
    sta 1024+(16*40)+10,x
    inx
    cpx #20
    bne nostr2loop
    jmp str2end
drawstr2
    ldx #0
str2loop
    lda pressfirestr,x
    sta 1024+(16*40)+10,x
    inx
    cpx #20
    bne str2loop
str2end
    lda blinkflag
    eor #$01
    sta blinkflag

    lda #$80
    jsr wait
    
    lda $dc00
    and #16
    bne titleloop
    
    jsr gamestartsnd
    
    lda #$00
    sta $d015 ;wylaczyc sprity
    
    rts
.bend

;------------------------------------------------
;funkcje odpowiadajace za efekty dzwiekowe

initsnd
    lda #$0f
    sta $d418

    rts
    
silent
    lda #$00
    sta $d404
    
    rts
    
ptssnd
    ;czestotliwosc
    lda #$ac
    sta $d400
    lda #$39
    sta $d401
    
    ;pulse
    ;lda #$00
    ;sta $d402
    ;lda #$ff
    ;sta $d403
    
    ;adsr
    lda #$00
    sta $d405
    lda #$f0
    sta $d406
    
    lda #$21
    sta $d404

    rts
    
gameoversnd
.block
    ldx #2
begin
    txa
    pha
    
    ;adsr
    lda #$00
    sta $d405
    lda #$f0
    sta $d406
    
    lda #$10
    sta $d400
    lda #$06
    sta $d401
    lda #$21
    sta $d404
    lda #$20
    jsr wait
    
    lda #$b9
    sta $d400
    lda #$05
    sta $d401
    lda #$20
    jsr wait
    
    jsr silent
    lda #$20
    jsr wait
    
    lda #$d0
    sta $d400
    lda #$04
    sta $d401
    lda #$21
    sta $d404
    lda #$40
    jsr wait
    
    jsr silent
    lda #$20
    jsr wait
    
    pla
    tax
    
    dex
    bne begin
    
    rts
.bend

advsnd
.block
    lda #$00
    sta $d405
    lda #$f0
    sta $d406
    
    lda #$61
    sta $d400
    lda #$33
    sta $d401
    lda #$21
    sta $d404
    lda #$20
    jsr wait
    
    lda #$6f
    sta $d400
    lda #$36
    sta $d401
    lda #$20
    jsr wait
    
    jsr silent
    lda #$20
    jsr wait
    
    lda #$bc
    sta $d400
    lda #$40
    sta $d401
    lda #$21
    sta $d404
    lda #$20
    jsr wait
    
    lda #$95
    sta $d400
    lda #$44
    sta $d401
    lda #$21
    sta $d404
    lda #$20
    jsr wait
    
    lda #$bc
    sta $d400
    lda #$40
    sta $d401
    lda #$21
    sta $d404
    lda #$20
    jsr wait
    
    lda #$95
    sta $d400
    lda #$44
    sta $d401
    lda #$21
    sta $d404
    lda #$20
    jsr wait
    
    jsr silent

    rts
.bend

gamestartsnd
.block
    ldx #2
loop
    txa
    pha
    
    ;czestotliwosc
    lda #$93
    sta $d400
    lda #$08
    sta $d401
    ;adsr
    lda #$44
    sta $d405
    lda #$f0
    sta $d406
    
    lda #$11
    sta $d404
    
    lda #$80
    jsr wait
    
    jsr silent
    lda #40
    jsr wait
    
    pla
    tax
    dex
    bne loop
    
    rts
.bend

;------------------------------------------------
;funkcja spr czy jest awans na wyzszy poziom

chklvlpts
.block
    sec
    lda maxlvlscore+1
    cmp lvlscore+1
    bcc *+5
    beq *+3
    rts
    
    inc curlvl
    sec
    lda curlvl
    cmp #maxlevel
    bcc *+9
    beq *+7
    lda #0
    sta curlvl
    
    jsr loadlvl
    jsr drawscore
    
    jsr advsnd
    
    rts
.bend

;------------------------------------------------

drawscore
.block
    ldx #0
loop
    lda scorestr,x
    sta 1024,x
    inx
    cpx #24
    bne loop
    
    clc
    
    lda score
    and #$0f
    adc #48
    sta 1035
    lda score
    and #$f0
    lsr
    lsr
    lsr
    lsr
    adc #48
    sta 1034
    lda score+1
    and #$0f
    adc #48
    sta 1033
    lda score+1
    and #$f0
    lsr
    lsr
    lsr
    lsr
    adc #48
    sta 1032
    lda score+2
    and #$0f
    adc #48
    sta 1031
    lda score+2
    and #$f0
    lsr
    lsr
    lsr
    lsr
    adc #48
    sta 1030
    
    lda hiscore
    and #$0f
    adc #48
    sta 1047
    lda hiscore
    and #$f0
    lsr
    lsr
    lsr
    lsr
    adc #48
    sta 1046
    lda hiscore+1
    and #$0f
    adc #48
    sta 1045
    lda hiscore+1
    and #$f0
    lsr
    lsr
    lsr
    lsr
    adc #48
    sta 1044
    lda hiscore+2
    and #$0f
    adc #48
    sta 1043
    lda hiscore+2
    and #$f0
    lsr
    lsr
    lsr
    lsr
    adc #48
    sta 1042
    
    rts
.bend

;------------------------------------------------

readjoy
.block
    lda $dc00
    and #1
    bne *+7
    lda #1
    sta curdir
    
    lda $dc00
    and #2
    bne *+7
    lda #2
    sta curdir
    
    lda $dc00
    and #4
    bne *+7
    lda #4
    sta curdir

    lda $dc00
    and #8
    bne *+7
    lda #8
    sta curdir
    
    rts
.bend

;------------------------------------------------

waitjoyfire
.block
loop
    lda $dc00
    and #16
    bne loop
    
loop2
    lda $dc00
    and #16
    beq loop2
    
    rts
.bend

;------------------------------------------------

waitjoydir
.block
loop
    lda $dc00
    and #1
    bne *+8
    lda #1
    sta curdir
    rts
    
    lda $dc00
    and #2
    bne *+8
    lda #2
    sta curdir
    rts
    
    lda $dc00
    and #4
    bne *+8
    lda #4
    sta curdir
    rts

    lda $dc00
    and #8
    bne *+8
    lda #8
    sta curdir
    rts
    
    jmp loop
.bend

;------------------------------------------------
;funkcja aktualizujaca pozycje weza

advsnake
.block
    ;zignorowac przeciwny do obecnego
    ;kierunek
    lda curdir
    cmp #1
    bne *+12
    lda prevdir
    cmp #2
    bne *+5
    sta curdir
    
    lda curdir
    cmp #2
    bne *+12
    lda prevdir
    cmp #1
    bne *+5
    sta curdir
    
    lda curdir
    cmp #4
    bne *+12
    lda prevdir
    cmp #8
    bne *+5
    sta curdir
    
    lda curdir
    cmp #8
    bne *+12
    lda prevdir
    cmp #4
    bne *+5
    sta curdir

    ;usunac poprzedni jezyczek
    ldy #0
    lda (tongueaddr),y
    sec
    cmp #tongueup
    bcc notongue
    cmp #tongueright+1
    bcs notongue
    lda #0
    sta (tongueaddr),y
notongue

    lda snakebegin
    sta scraddr
    lda snakebegin+1
    sta scraddr+1
    
    clc
    lda snakebegin+1
    adc #$d4
    sta coladdr+1
    lda snakebegin
    sta coladdr
    
    ;obliczyc nowa pozycje jezyczka
    lda curdir
    cmp #1
    beq tngup
    cmp #2
    beq tngdown
    cmp #4
    beq tngleft
    cmp #8
    beq tngright
tngup
    sec
    lda scraddr
    sbc #80
    sta scraddr
    bcs *+4
    dec scraddr+1
    sec
    lda coladdr
    sbc #80
    sta coladdr
    bcs *+4
    dec coladdr+1
    jmp check
tngdown
    clc
    lda scraddr
    adc #80
    sta scraddr
    bcc *+4
    inc scraddr+1
    clc
    lda coladdr
    adc #80
    sta coladdr
    bcc *+4
    inc coladdr+1
    jmp check
tngleft
    sec
    lda scraddr
    sbc #2
    sta scraddr
    bcs *+4
    dec scraddr+1
    sec
    lda coladdr
    sbc #2
    sta coladdr
    bcs *+4
    dec coladdr+1
    jmp check
tngright
    clc
    lda scraddr
    adc #2
    sta scraddr
    bcc *+4
    inc scraddr+1
    clc
    lda coladdr
    adc #2
    sta coladdr
    bcc *+4
    inc coladdr+1
    jmp check
    
check
    ;spr czy mozna nadpisac
    ldy #0
    lda (scraddr),y
    cmp #0
    bne notongue2
    lda tongueflag
    cmp #0
    beq notongue2
    
    ;przestawic jezyczek (nowa pozycja gotowa)
    ldy #0
    lda curdir
    cmp #1
    bne *+6
    lda #tongueup
    sta (scraddr),y
    cmp #2
    bne *+6
    lda #tonguedown
    sta (scraddr),y
    cmp #4
    bne *+6
    lda #tongueleft
    sta (scraddr),y
    cmp #8
    bne *+6
    lda #tongueright
    sta (scraddr),y
    ;zapisac kolor
    lda #2 ;czerwony
    sta (coladdr),y
notongue2

    lda scraddr
    sta tongueaddr
    lda scraddr+1
    sta tongueaddr+1
    
    lda tongueflag
    eor #$01
    sta tongueflag
    
    ;NAJPIERW GLOWA WEZA

    lda snakebegin
    sta scraddr
    lda snakebegin+1
    sta scraddr+1
    
    clc
    lda snakebegin+1
    adc #$d4
    sta coladdr+1
    lda snakebegin
    sta coladdr
    
    ;obliczyc nowa pozycje glowy
    lda curdir
    cmp #1
    beq up
    cmp #2
    beq down
    cmp #4
    beq left
    cmp #8
    beq right
up
    sec
    lda scraddr
    sbc #40
    sta scraddr
    bcs *+4
    dec scraddr+1
    sec
    lda coladdr
    sbc #40
    sta coladdr
    bcs *+4
    dec coladdr+1
    jmp next
down
    clc
    lda scraddr
    adc #40
    sta scraddr
    bcc *+4
    inc scraddr+1
    clc
    lda coladdr
    adc #40
    sta coladdr
    bcc *+4
    inc coladdr+1
    jmp next
left
    sec
    lda scraddr
    sbc #1
    sta scraddr
    bcs *+4
    dec scraddr+1
    sec
    lda coladdr
    sbc #1
    sta coladdr
    bcs *+4
    dec coladdr+1
    jmp next
right
    clc
    lda scraddr
    adc #1
    sta scraddr
    bcc *+4
    inc scraddr+1
    clc
    lda coladdr
    adc #1
    sta coladdr
    bcc *+4
    inc coladdr+1
    jmp next
    
next ;spr zderzenia
    ldy #0
    lda (scraddr),y
    sec
    cmp #headup
    bcc next2
    cmp #walldownright+1
    bcs next2
    jmp gameover ;GAME OVER jezeli zderzenie
next2
    ldy #0
    lda (scraddr),y
    sec
    cmp #candy
    bcc next3
    cmp #apple+1
    bcs next3
    lda #1  ;ustawic flage jesli waz
    sta scoreflag   ;sie wydluza
    jsr advscore ;dodac punkty
    jmp next4
next3
    lda #0
    sta scoreflag
    
next4
    ;przestawic glowe weza (nowa pozycja gotowa)
    ldy #0
    lda curdir
    cmp #1
    bne *+6
    lda #headup
    sta (scraddr),y
    cmp #2
    bne *+6
    lda #headdown
    sta (scraddr),y
    cmp #4
    bne *+6
    lda #headleft
    sta (scraddr),y
    cmp #8
    bne *+6
    lda #headright
    sta (scraddr),y
    ;zapisac kolor glowy weza (w pamieci kolorow)
    lda #9
    sta (coladdr),y
    
    ;nadpisac "szyje" weza
    lda curdir
    cmp prevdir
    bne sturn
    cmp #1
    beq svert
    cmp #2
    beq svert
    cmp #4
    beq shoriz
    cmp #8
    beq shoriz
svert
    ldy #0
    lda #bodyvert
    sta (snakebegin),y ;stara glowa
    jmp next5
shoriz
    ldy #0
    lda #bodyhoriz
    sta (snakebegin),y
    jmp next5
sturn
    lda prevdir
    cmp #8
    bne *+12
    lda curdir
    cmp #2
    bne *+5
    jmp sturnleftdown
    lda prevdir
    cmp #1
    bne *+12
    lda curdir
    cmp #4
    bne *+5
    jmp sturnleftdown
    
    lda prevdir
    cmp #1
    bne *+12
    lda curdir
    cmp #8
    bne *+5
    jmp sturndownright
    lda prevdir
    cmp #4
    bne *+12
    lda curdir
    cmp #2
    bne *+5
    jmp sturndownright
    
    lda prevdir
    cmp #8
    bne *+12
    lda curdir
    cmp #1
    bne *+5
    jmp sturnleftup
    lda prevdir
    cmp #2
    bne *+12
    lda curdir
    cmp #4
    bne *+5
    jmp sturnleftup
    
    lda prevdir
    cmp #2
    bne *+12
    lda curdir
    cmp #8
    bne *+5
    jmp sturnupright
    lda prevdir
    cmp #4
    bne *+12
    lda curdir
    cmp #1
    bne *+5
    jmp sturnupright
    
sturnleftdown
    ldy #0
    lda #turnleftdown
    sta (snakebegin),y
    jmp next5
sturndownright
    ldy #0
    lda #turndownright
    sta (snakebegin),y
    jmp next5
sturnleftup
    ldy #0
    lda #turnleftup
    sta (snakebegin),y
    jmp next5
sturnupright
    ldy #0
    lda #turnupright
    sta (snakebegin),y
    jmp next5
next5
    
    ;zapisac nowa pozycje glowy
    ;na nastepne wywolanie funkcji
    lda scraddr
    sta snakebegin
    lda scraddr+1
    sta snakebegin+1
    
    ;TERAZ OGON WEZA
    
    lda scoreflag ;spr flage
    cmp #0
    beq *+5
    jmp funcend ;i nie przesuwac ogona jak true
    
    ;obliczyć nowy adres
    lda snakeend
    sta scraddr
    lda snakeend+1
    sta scraddr+1
    
    ldy #0
    lda (snakeend),y
    cmp #tailup
    beq tup
    cmp #taildown
    beq tdown
    cmp #tailleft
    beq tleft
    cmp #tailright
    beq tright
tup
    sec
    lda scraddr
    sbc #40
    bcs *+4
    dec scraddr+1
    jmp next6
tdown
    clc
    lda scraddr
    adc #40
    bcc *+4
    inc scraddr+1
    jmp next6
tleft
    sec
    lda scraddr
    sbc #1
    bcs *+4
    dec scraddr+1
    jmp next6
tright
    clc
    lda scraddr
    adc #1
    bcc *+4
    inc scraddr+1
    jmp next6
next6
    sta scraddr

    ;nadpisac nowy ogon
    ldy #0
    lda (scraddr),y
    cmp #bodyvert
    bne *+12
    lda (snakeend),y
    cmp #tailup
    beq tup2
    cmp #taildown
    beq tdown2

    lda (scraddr),y
    cmp #bodyhoriz
    bne *+12
    lda (snakeend),y
    cmp #tailleft
    beq tleft2
    cmp #tailright
    beq tright2

    lda (scraddr),y
    cmp #turnleftdown
    bne *+12
    lda (snakeend),y
    cmp #tailright
    beq tdown2
    cmp #tailup
    beq tleft2

    lda (scraddr),y
    cmp #turndownright
    bne *+12
    lda (snakeend),y
    cmp #tailup
    beq tright2
    cmp #tailleft
    beq tdown2

    lda (scraddr),y
    cmp #turnleftup
    bne *+12
    lda (snakeend),y
    cmp #tailright
    beq tup2
    cmp #taildown
    beq tleft2

    lda (scraddr),y
    cmp #turnupright
    bne *+12
    lda (snakeend),y
    cmp #taildown
    beq tright2
    cmp #tailleft
    beq tup2

tup2
    lda #tailup
    sta (scraddr),y
    jmp next7
tdown2
    lda #taildown
    sta (scraddr),y
    jmp next7
tleft2
    lda #tailleft
    sta (scraddr),y
    jmp next7
tright2
    lda #tailright
    sta (scraddr),y
    jmp next7
next7

    ;usunac poprzedni ogon
    ldy #0
    lda #0
    sta (snakeend),y

    ;zaktualizowac snakeend
    lda scraddr
    sta snakeend
    lda scraddr+1
    sta snakeend+1
    
funcend
    ;zapisac obecny kierunek jako
    ;poprzedni
    lda curdir
    sta prevdir

    rts
.bend

;------------------------------------------------
;funkcja dodaje punkty do wyniku gracza
;aktualizuje w razie czego hiscore

advscore
.block
    jsr ptssnd ;efekt dzwiekowy

    ldy #0
    lda (scraddr),y
    cmp #candy
    beq ptscandy
    cmp #cherry
    beq ptscherry
    cmp #lemon
    beq ptslemon
    cmp #apple
    beq ptsapple
    
ptscandy
    lda #$25
    jmp next
ptscherry
    lda #$15
    jmp next
ptslemon
    lda #$10
    jmp next
ptsapple
    lda #$05
    jmp next
next
    sta index
    
    clc ;najpierw score
    sed
    lda score
    adc index
    sta score
    lda score+1
    adc #0
    sta score+1
    lda score+2
    adc #0
    sta score+2
    
    clc ;teraz ukryte lvlscore
    lda lvlscore
    adc index
    sta lvlscore
    lda lvlscore+1
    adc #0
    sta lvlscore+1
    lda lvlscore+2
    adc #0
    sta lvlscore+2
    
    ;spr score > hiscore
    sec
    lda hiscore+2
    cmp score+2
    bcc advhi
    bne funcend
    lda hiscore+1
    cmp score+1
    bcc advhi
    bne funcend
    lda hiscore
    cmp score
    bcc advhi
    bne funcend
advhi
    lda score
    sta hiscore
    lda score+1
    sta hiscore+1
    lda score+2
    sta hiscore+2

funcend
    jsr drawscore
    
    cld
    rts
.bend

;------------------------------------------------
;funkcja/ekran GAME OVER

gameover
.block
    ldx #0
loop
    lda gameoverstr,x
    sta 1024+(12*40)+15,x
    inx
    cpx #9
    bne loop
    
    ldx #0
    lda #1
loop2
    sta $d800+(12*40)+15,x
    inx
    cpx #9
    bne loop2
    
    jsr gameoversnd
    
    jsr waitjoyfire

    jmp reset
.bend

;------------------------------------------------
;funkcja wczytujaca poziom
;argumenty: curlvl

loadlvl
.block
    ;inicjalizacja adresow
    ldx #0
    lda #<level0
    sta lvladdr
    lda #>level0
    sta lvladdr+1
addrloop
    cpx curlvl
    beq *+9
    inx
    clc
    adc #04
    jmp addrloop
    
    sta lvladdr+1
    
    lda #$04
    sta scraddr+1
    lda #$00
    sta scraddr
    
    lda #$d8
    sta coladdr+1
    lda #$00
    sta coladdr
    
    ;petla przepisujaca co trzeba
    ldx #5
majorloop
    ldy #0
minorloop ;kopiowanie 200 bajtow
    lda (lvladdr),y
    sta (scraddr),y
    pha
    jsr loadlvlcolor ;przypisanie koloru (patrz nizej)
    pla
    jsr snakeinit
    iny
    cpy #200
    bne minorloop
    ;else -> przesun adresy o nastepne 200
    clc
    lda lvladdr
    adc #200
    bcc *+4
    inc lvladdr+1
    sta lvladdr
    clc
    lda scraddr
    adc #200
    bcc *+4
    inc scraddr+1
    sta scraddr
    clc
    lda coladdr
    adc #200
    bcc *+4
    inc coladdr+1
    sta coladdr
    dex
    bne majorloop
    
    lda #8
    sta prevdir
    sta curdir
    
    lda #$01
    sta pauseflag
    
    lda #$00
    sta lvlscore
    sta lvlscore+1
    sta lvlscore+2
    
    ldx #$00
    lda #$00
    sta maxlvlscore
    sta maxlvlscore+1
    sta maxlvlscore+2
    lda #$01
scoreloop
    cpx curlvl
    beq *+11
    clc
    sed
    adc #01
    cld
    inx
    jmp scoreloop
    sta maxlvlscore+1 ;zapisujemy

    rts
.bend

loadlvlcolor ;pomocnicza funkcja
.block  ;nie narusza rejestrow x ani y
    sec ;pobiera i zmienia akumulator
    cmp #64
    bcc *+9
    cmp #78
    bcs *+5
    jmp colorbrown
    sec
    cmp #82
    bcc *+9
    cmp #86
    bcs *+5
    jmp colorlgray
    cmp #86
    beq colorblue
    cmp #87
    beq colorred
    cmp #88
    beq coloryellow
    cmp #89
    beq colorgreen
    jmp colorend
colorblue
    lda #6
    sta (coladdr),y
    jmp colorend
colorred
    lda #2
    sta (coladdr),y
    jmp colorend
coloryellow
    lda #7
    sta (coladdr),y
    jmp colorend
colorgreen
    lda #5
    sta (coladdr),y
    jmp colorend
colorlgray
    lda #15
    sta (coladdr),y
    jmp colorend
colorbrown
    lda #9
    sta (coladdr),y
    jmp colorend
colorend

    rts
.bend

;kolejna funkcja pomocnicza
;wyluskuje wspolrzedne (wlasc. adres)
;glowy i ogona weza
snakeinit ;nie dotyka x i y
.block ;pobiera i zmienia akumulator
    sty index
    
    clc
    cmp #64
    bcc *+9
    cmp #68
    bcs *+5
    jmp inithead
    
    clc
    cmp #74
    bcc *+9
    cmp #78
    bcs *+5
    jmp inittail
    
    jmp initend
    
inithead
    lda scraddr+1
    sta snakebegin+1
    clc
    lda scraddr
    adc index
    sta snakebegin
    bcc initend
    inc snakebegin+1
    
inittail
    lda scraddr+1
    sta snakeend+1
    clc
    lda scraddr
    adc index
    sta snakeend
    bcc initend
    inc snakeend+1

initend
    rts
.bend

;------------------------------------------------

initcharset
    lda $dc0e ;zatrzymac timer
    and #$fe
    sta $dc0e
    
    lda $01 ;pokazac character ROM
    and #$fb
    sta $01
    
    ;skopiowac czesc charsetu
    ldx #$00
loop1
    lda $d000,x
    sta $2000,x
    inx
    bne loop1
    
    ldx #$00
loop2
    lda $d100,x
    sta $2100,x
    inx
    bne loop2
    
    lda $01 ;schowac character ROM
    ora #$04
    sta $01
    
    lda $dc0e ;wlaczyc spowrotem timer
    ora #$01
    sta $dc0e
    
    ;zrobic zeby znak 0 byl pusty (a nie @)
    lda #$00
    sta $2000
    sta $2001
    sta $2002
    sta $2003
    sta $2004
    sta $2005
    sta $2006
    sta $2007

    ;zapisac adres ekranu i nowego charsetu
    lda #$18
    sta $d018

    rts
    
;------------------------------------------------

wait ;funkcja opozniajaca
.block
    tay ;akumulator = jak dlugo
    
majorloop
    ldx #$ff
    
minorloop
    nop
    nop
    nop
    dex
    bne minorloop
    
    dey
    bne majorloop
    
    rts
.bend

;------------------------------------------------

clrscr
.block
    lda #32 ;spacja
    ldx #0
clrloop    
    sta 1024,x
    sta 1224,x
    sta 1424,x
    sta 1624,x
    sta 1824,x
    inx
    cpx #200
    bne clrloop
    
    lda #1 ;na bialo
    ldx #0
colloop
    sta 55296,x
    sta 55496,x
    sta 55696,x
    sta 55896,x
    sta 56096,x
    inx
    cpx #200
    bne colloop
    
    rts
.bend

;------------------------------------------------
;------------------------------------------------
;Zmienne w pamieci (ale nie zero-page)

score
    .byte $00, $00, $00
hiscore
    .byte $10, $14, $00
pauseflag
    .byte $01
 
curdir  ;aktualny kierunek ruch (z joysticka)
    .byte $08   ;1-gora,2-dol,4-lewo,8-prawo
prevdir ;dla uproszczenia funkcji advsnake
    .byte $08
scoreflag
    .byte $00 ;flaga czy waz wydluza sie
 
curlvl  ;aktualny poziom
    .byte $00
lvlscore ;punkty z aktualnego poziomu
    .byte $00, $00, $00
maxlvlscore ;maximum pkt do awansu
    .byte $00, $01, $00
    
tongueflag
    .byte $00

index ;na wszelaki uzytek
    .byte $00
    
scorestr
    .screen "score:000000   hi:000000" ;len=24
gameoverstr
    .screen "game over" ;len=9
    
;stringi do ekranu tytułowego
gamenamestr
    .screen "wild snake boa" ;len=14
pressfirestr
    .screen "press fire to start!" ;len=20
authorstr
    .screen "a game by tobiasz stamborski" ;len=28
blinkflag
    .byte $01

;------------------------------------------------
;------------------------------------------------
    
    *=$2200
    .offs $2200-*
    
    ;glowa weza w gore
    .byte $18, $3c, $7e, $99, $bd, $ff, $7e, $3c
    ;glowa weza w dol
    .byte $3c, $7e, $ff, $bd, $99, $7e, $3c, $18
    ;glowa weza w lewo
    .byte $1c, $26, $6f, $ff, $ff, $6f, $26, $1c
    ;glowa weza w prawo
    .byte $38, $64, $f6, $ff, $ff, $f6, $64, $38
    
    ;cialo weza pionowo
    .byte $3c, $3c, $3c, $3c, $3c, $3c, $3c, $3c
    ;cialo weza poziomo
    .byte $00, $00, $ff, $ff, $ff, $ff, $00, $00
    
    ;zakrety
    ;lewo -> gora
    .byte $3c, $3c, $fc, $fc, $f8, $f0, $00, $00
    ;gora -> prawo
    .byte $3c, $3c, $3f, $3f, $1f, $0f, $00, $00
    ;lewo -> dol
    .byte $00, $00, $f0, $f8, $fc, $fc, $3c, $3c
    ;dol -> prawo
    .byte $00, $00, $0f, $1f, $3f, $3f, $3c, $3c
    
    ;ogon weza w gore
    .byte $3c, $1c, $1c, $18, $18, $08, $08, $00
    ;ogon weza w dol
    .byte $00, $08, $08, $18, $18, $1c, $1c, $3c
    ;ogon weza w lewo
    .byte $00, $00, $e0, $fe, $f8, $80, $00, $00
    ;ogon weza w prawo
    .byte $00, $00, $01, $1f, $7f, $07, $00, $00
    
    ;jezyk weza w gore
    .byte $00, $00, $00, $00, $00, $28, $10, $10
    ;jezyk weza w dol
    .byte $08, $08, $14, $00, $00, $00, $00, $00
    ;jezyk weza w lewo
    .byte $00, $00, $00, $04, $03, $04, $00, $00
    ;jezyk weza w prawo
    .byte $00, $00, $00, $20, $c0, $20, $00, $00
    
    ;sciana lewy-gorny
    .byte $fe, $fe, $fe, $00, $df, $df, $df, $00
    ;sciana prawy-gorny
    .byte $fe, $fe, $fe, $00, $df, $df, $df, $00
    ;sciana lewy-dolny
    .byte $fb, $fb, $fb, $00, $df, $df, $df, $00
    ;sciana prawy-dolny
    .byte $fb, $fb, $fb, $00, $df, $df, $df, $00
    
    ;cukierek
    .byte $00, $00, $bd, $ff, $bd, $00, $00, $00

    ;wisienka
    .byte $02, $06, $0a, $12, $66, $ef, $ef, $66
    
    ;cytryna
    .byte $00, $00, $3c, $7e, $ff, $7e, $3c, $00
    
    ;jablko
    .byte $02, $3c, $7e, $ff, $ff, $ff, $7e, $3c
    
;------------------------------------------------
;------------------------------------------------
;sprite bank

    *=$2400
    .offs $2400-*
    
titleupleft
    .byte $55,$15,$50,$14,$05,$40,$34,$05
    .byte $50,$3d,$15,$55,$ff,$3a,$95,$ff
    .byte $aa,$af,$3e,$95,$6a,$0b,$55,$56
    .byte $2d,$54,$15,$2d,$50,$05,$35,$54
    .byte $15,$35,$55,$55,$31,$6d,$6a,$30
    .byte $7b,$ff,$34,$1e,$95,$3c,$07,$c5
    .byte $0d,$45,$41,$0f,$55,$51,$0f,$d5
    .byte $53,$03,$ff,$cf,$00,$d6,$aa,$00

titleupright
    .byte $55,$80,$00,$15,$e8,$00,$15,$7e
    .byte $80,$55,$57,$e0,$55,$55,$7f,$55
    .byte $05,$57,$d4,$01,$51,$bd,$05,$40
    .byte $6b,$d5,$50,$56,$f5,$50,$45,$af
    .byte $d4,$41,$fa,$bf,$40,$7f,$ef,$51
    .byte $55,$7f,$95,$55,$57,$25,$45,$51
    .byte $25,$45,$50,$25,$01,$40,$a5,$01
    .byte $40,$b5,$45,$51,$bd,$45,$51,$00

titledownleft
    .byte $00,$55,$6a,$00,$55,$5a,$01,$15
    .byte $5a,$01,$14,$59,$01,$54,$54,$01
    .byte $55,$54,$01,$55,$54,$05,$55,$54
    .byte $35,$55,$70,$35,$57,$c0,$0d,$7c
    .byte $00,$03,$c0,$00,$00,$00,$00,$00
    .byte $00,$00,$00,$00,$00,$00,$00,$00
    .byte $00,$00,$00,$00,$00,$00,$00,$00
    .byte $00,$00,$00,$00,$00,$00,$00,$00

titledownright
    .byte $cd,$55,$55,$cf,$d5,$55,$c3,$f5
    .byte $55,$00,$ff,$d5,$00,$0f,$ff,$00
    .byte $00,$ff,$00,$00,$0f,$00,$00,$00
    .byte $00,$00,$00,$00,$00,$00,$00,$00
    .byte $00,$00,$00,$00,$00,$00,$00,$00
    .byte $00,$00,$00,$00,$00,$00,$00,$00
    .byte $00,$00,$00,$00,$00,$00,$00,$00
    .byte $00,$00,$00,$00,$00,$00,$00,$00

titletongue0
    .byte $00,$00,$00,$00,$00,$00,$00,$00
    .byte $00,$00,$00,$00,$00,$00,$00,$00
    .byte $00,$00,$00,$00,$00,$00,$00,$00
    .byte $00,$00,$00,$00,$00,$00,$00,$00
    .byte $00,$00,$00,$00,$00,$00,$00,$00
    .byte $00,$00,$00,$00,$00,$00,$00,$00
    .byte $00,$00,$00,$00,$00,$00,$00,$00
    .byte $00,$00,$00,$00,$00,$00,$00,$00

titletongue1
    .byte $00,$00,$02,$00,$00,$28,$00,$00
    .byte $08,$00,$00,$00,$00,$00,$00,$00
    .byte $00,$00,$00,$00,$00,$00,$00,$00
    .byte $00,$00,$00,$00,$00,$00,$00,$00
    .byte $00,$00,$00,$00,$00,$00,$00,$00
    .byte $00,$00,$00,$00,$00,$00,$00,$00
    .byte $00,$00,$00,$00,$00,$00,$00,$00
    .byte $00,$00,$00,$00,$00,$00,$00,$00

titletongue2
    .byte $00,$00,$02,$00,$00,$08,$00,$02
    .byte $a0,$00,$00,$20,$00,$00,$20,$00
    .byte $00,$20,$00,$00,$00,$00,$00,$00
    .byte $00,$00,$00,$00,$00,$00,$00,$00
    .byte $00,$00,$00,$00,$00,$00,$00,$00
    .byte $00,$00,$00,$00,$00,$00,$00,$00
    .byte $00,$00,$00,$00,$00,$00,$00,$00
    .byte $00,$00,$00,$00,$00,$00,$00,$00

titletongue3
    .byte $00,$00,$02,$00,$00,$28,$00,$00
    .byte $08,$00,$00,$00,$00,$00,$00,$00
    .byte $00,$00,$00,$00,$00,$00,$00,$00
    .byte $00,$00,$00,$00,$00,$00,$00,$00
    .byte $00,$00,$00,$00,$00,$00,$00,$00
    .byte $00,$00,$00,$00,$00,$00,$00,$00
    .byte $00,$00,$00,$00,$00,$00,$00,$00
    .byte $00,$00,$00,$00,$00,$00,$00,$00
    
;------------------------------------------------
;------------------------------------------------
;rozne gotowe poziomy do wczytywania
;przy pomocy funkcji loadlvl

    *=$3000
    .offs $3000-*
    ;poziom 0 - najprostszy

    .byte 00,00,00,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,00,00,00,    00,00,00,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,00,00,00
    .byte 82,83,82,83,82,83,82,83,82,83,  82,83,82,83,82,83,82,83,82,83,    82,83,82,83,82,83,82,83,82,83,  82,83,82,83,82,83,82,83,82,83
    .byte 84,85,84,85,84,85,84,85,84,85,  84,85,84,85,84,85,84,85,84,85,    84,85,84,85,84,85,84,85,84,85,  84,85,84,85,84,85,84,85,84,85
    .byte 82,83,00,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,00,00,00,    00,00,00,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,00,82,83
    .byte 84,85,00,77,69,69,69,69,67,00,  00,00,00,00,00,00,00,00,00,00,    00,00,00,00,00,00,00,00,00,00,  00,00,00,00,00,00,86,00,84,85
    
    .byte 82,83,00,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,00,00,00,    00,00,00,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,00,82,83
    .byte 84,85,00,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,00,00,00,    00,00,00,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,00,84,85
    .byte 82,83,00,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,00,00,00,    00,00,00,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,00,82,83
    .byte 84,85,00,00,00,00,00,00,89,00,  00,00,00,00,00,00,00,00,00,00,    00,00,00,00,00,00,00,00,00,00,  00,89,00,00,00,00,00,00,84,85
    .byte 82,83,00,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,00,00,00,    00,00,00,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,00,82,83

    .byte 84,85,00,00,00,00,00,00,00,00,  00,00,00,00,00,00,87,00,00,00,    00,00,00,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,00,84,85
    .byte 82,83,00,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,00,00,00,    00,00,00,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,00,82,83
    .byte 84,85,00,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,00,00,00,    00,00,00,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,00,84,85
    .byte 82,83,00,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,00,00,00,    00,00,00,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,00,82,83
    .byte 84,85,00,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,00,00,00,    00,00,00,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,00,84,85
    
    .byte 82,83,00,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,00,00,00,    00,00,00,87,00,00,00,00,00,00,  00,00,00,00,00,00,00,00,82,83
    .byte 84,85,00,00,00,00,00,00,89,00,  00,00,00,00,00,00,00,00,00,00,    00,00,00,00,00,00,00,00,00,00,  00,89,00,00,00,00,00,00,84,85
    .byte 82,83,00,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,00,00,00,    00,00,00,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,00,82,83
    .byte 84,85,00,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,00,00,00,    00,00,00,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,00,84,85
    .byte 82,83,00,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,00,00,00,    00,00,00,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,00,82,83
    
    .byte 84,85,00,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,00,00,00,    00,00,00,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,00,84,85
    .byte 82,83,86,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,00,00,00,    00,00,00,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,00,82,83
    .byte 84,85,00,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,00,00,00,    00,00,00,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,00,84,85
    .byte 82,83,82,83,82,83,82,83,82,83,  82,83,82,83,82,83,82,83,82,83,    82,83,82,83,82,83,82,83,82,83,  82,83,82,83,82,83,82,83,82,83
    .byte 84,85,84,85,84,85,84,85,84,85,  84,85,84,85,84,85,84,85,84,85,    84,85,84,85,84,85,84,85,84,85,  84,85,84,85,84,85,84,85,84,85
    
    *=$3400
    .offs $3400-*
    ;poziom 1

    .byte 00,00,00,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,00,00,00,    00,00,00,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,00,00,00
    .byte 82,83,82,83,82,83,82,83,82,83,  82,83,82,83,82,83,82,83,82,83,    82,83,82,83,82,83,82,83,82,83,  82,83,82,83,82,83,82,83,82,83
    .byte 84,85,84,85,84,85,84,85,84,85,  84,85,84,85,84,85,84,85,84,85,    84,85,84,85,84,85,84,85,84,85,  84,85,84,85,84,85,84,85,84,85
    .byte 82,83,00,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,00,00,00,    00,00,00,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,00,82,83
    .byte 84,85,00,77,69,69,69,69,69,69,  67,00,00,00,00,00,00,00,00,00,    86,00,00,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,00,84,85
    
    .byte 82,83,00,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,00,00,83,    82,00,00,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,00,82,83
    .byte 84,85,00,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,00,00,85,    84,00,00,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,00,84,85
    .byte 82,83,00,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,00,00,83,    82,00,00,00,00,00,00,00,00,00,  00,00,00,00,00,89,00,00,82,83
    .byte 84,85,00,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,00,00,85,    84,00,00,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,00,84,85
    .byte 82,83,00,00,00,00,00,00,00,00,  00,00,00,00,00,00,88,00,88,83,    82,00,00,00,00,00,00,00,00,00,  00,00,00,89,00,00,00,00,82,83

    .byte 84,85,00,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,00,00,85,    84,00,00,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,00,84,85
    .byte 82,83,00,00,00,00,00,00,00,00,  00,00,00,00,00,00,88,00,88,83,    82,00,00,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,00,82,83
    .byte 84,85,00,00,00,00,00,00,00,00,  00,85,84,85,84,85,84,85,84,85,    84,85,84,85,84,85,84,85,84,00,  00,00,00,00,00,00,00,00,84,85
    .byte 82,83,00,00,00,00,00,00,00,00,  00,86,00,00,00,00,00,00,00,83,    82,88,00,88,00,00,00,00,86,00,  00,00,00,00,00,00,00,00,82,83
    .byte 84,85,00,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,00,00,85,    84,00,00,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,00,84,85
    
    .byte 82,83,00,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,00,00,83,    82,88,00,88,00,00,00,00,00,00,  00,00,00,00,00,00,00,00,82,83
    .byte 84,85,00,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,00,00,85,    84,00,00,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,00,84,85
    .byte 82,83,00,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,00,00,83,    82,00,00,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,00,82,83
    .byte 84,85,00,89,00,00,00,00,00,00,  00,00,00,00,00,00,00,00,00,85,    84,00,00,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,00,84,85
    .byte 82,83,00,00,89,00,00,00,00,00,  00,00,00,00,00,00,00,00,00,83,    82,00,00,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,00,82,83
    
    .byte 84,85,00,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,00,00,86,    00,00,00,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,00,84,85
    .byte 82,83,00,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,00,00,00,    00,00,00,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,00,82,83
    .byte 84,85,00,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,00,00,00,    00,00,00,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,00,84,85
    .byte 82,83,82,83,82,83,82,83,82,83,  82,83,82,83,82,83,82,83,82,83,    82,83,82,83,82,83,82,83,82,83,  82,83,82,83,82,83,82,83,82,83
    .byte 84,85,84,85,84,85,84,85,84,85,  84,85,84,85,84,85,84,85,84,85,    84,85,84,85,84,85,84,85,84,85,  84,85,84,85,84,85,84,85,84,85
    
    *=$3800
    .offs $3800-*
    ;poziom 2

    .byte 00,00,00,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,00,00,00,    00,00,00,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,00,00,00
    .byte 82,83,82,83,82,83,82,83,82,83,  82,83,82,83,82,83,82,83,82,83,    82,83,82,83,82,83,82,83,82,83,  82,83,82,83,82,83,82,83,82,83
    .byte 84,85,84,85,84,85,84,85,84,85,  84,85,84,85,84,85,84,85,84,85,    84,85,84,85,84,85,84,85,84,85,  84,85,84,85,84,85,84,85,84,85
    .byte 82,83,00,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,00,00,00,    00,00,00,00,00,00,00,00,00,00,  00,00,00,00,89,00,00,00,82,83
    .byte 84,85,00,77,69,69,69,69,69,69,  69,67,00,00,00,00,00,00,00,00,    00,00,00,00,00,00,00,00,00,00,  00,00,00,89,00,00,00,00,84,85
    
    .byte 82,83,00,00,00,00,00,00,82,83,  82,83,82,83,82,83,82,83,82,00,    82,83,82,83,82,00,82,83,82,83,  00,00,00,00,00,00,00,00,82,83
    .byte 84,85,00,00,00,00,00,00,84,85,  00,00,00,00,00,00,00,00,00,00,    00,00,00,00,00,00,00,86,84,85,  00,00,00,00,00,00,00,00,84,85
    .byte 82,83,00,00,00,00,00,00,82,83,  00,00,00,00,00,00,00,00,00,00,    00,00,00,00,00,00,00,86,82,83,  88,00,00,00,00,00,00,00,82,83
    .byte 84,85,00,00,00,00,00,00,84,85,  00,00,00,00,00,00,00,00,00,00,    00,00,00,00,00,00,00,00,84,85,  89,00,00,00,00,00,00,00,84,85
    .byte 82,83,00,00,00,00,00,00,82,83,  87,00,00,00,00,00,00,00,00,00,    00,00,00,00,00,00,00,00,82,83,  89,00,00,00,00,00,00,00,82,83

    .byte 84,85,00,00,00,00,00,00,84,85,  87,00,00,00,00,00,00,00,00,00,    00,00,00,00,00,00,00,00,84,85,  00,00,00,00,00,00,00,00,84,85
    .byte 82,83,00,88,00,00,00,00,82,83,  00,00,00,00,00,00,00,00,00,88,    00,88,00,00,00,00,00,00,82,83,  00,00,00,00,00,00,00,00,82,83
    .byte 84,85,00,00,00,00,00,00,84,85,  00,00,00,00,00,00,00,00,00,00,    00,00,00,00,00,00,00,88,84,85,  00,89,89,00,00,00,00,00,84,85
    .byte 82,83,00,00,00,00,00,00,82,83,  00,00,00,00,00,00,00,00,00,88,    00,88,00,00,00,00,00,88,82,83,  00,00,00,00,00,00,00,00,82,83
    .byte 84,85,00,00,00,00,00,00,84,85,  00,00,00,00,00,00,00,00,00,00,    00,00,00,00,00,00,00,00,84,85,  00,00,00,00,00,00,00,00,84,85
    
    .byte 82,83,00,00,00,00,00,00,82,83,  00,00,00,00,00,00,00,00,00,00,    00,00,00,00,00,00,00,00,82,83,  00,00,00,00,00,00,00,00,82,83
    .byte 84,85,00,00,00,00,00,00,84,85,  00,00,00,00,00,00,00,00,00,00,    00,00,00,00,00,00,00,00,84,85,  89,00,00,00,00,00,00,00,84,85
    .byte 82,83,00,00,00,00,00,00,82,83,  86,00,00,00,00,00,00,00,00,00,    00,00,00,00,00,00,00,00,82,83,  89,00,00,00,00,00,00,00,82,83
    .byte 84,85,00,00,00,87,00,00,84,85,  86,00,00,00,00,00,00,00,00,00,    00,00,00,00,00,00,00,00,84,85,  88,00,00,00,00,00,00,00,84,85
    .byte 82,83,00,00,00,00,87,00,82,83,  82,83,82,83,82,83,82,83,82,83,    82,83,82,83,82,83,82,83,82,83,  00,00,00,00,00,00,00,00,82,83
    
    .byte 84,85,00,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,00,00,00,    00,00,00,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,00,84,85
    .byte 82,83,00,00,00,00,00,00,00,00,  00,00,00,00,00,00,89,00,00,00,    89,00,00,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,00,82,83
    .byte 84,85,00,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,00,00,00,    00,00,00,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,00,84,85
    .byte 82,83,82,83,82,83,82,83,82,83,  82,83,82,83,82,83,82,83,82,83,    82,83,82,83,82,83,82,83,82,83,  82,83,82,83,82,83,82,83,82,83
    .byte 84,85,84,85,84,85,84,85,84,85,  84,85,84,85,84,85,84,85,84,85,    84,85,84,85,84,85,84,85,84,85,  84,85,84,85,84,85,84,85,84,85
    
    *=$3c00
    .offs $3c00-*
    ;poziom 3

    .byte 00,00,00,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,00,00,00,    00,00,00,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,00,00,00
    .byte 82,83,82,83,82,83,82,83,82,83,  82,83,82,83,82,83,82,83,82,83,    82,83,82,83,82,83,82,83,82,83,  82,83,82,83,82,83,82,83,82,83
    .byte 84,85,84,85,84,85,84,85,84,85,  84,85,84,85,84,85,84,85,84,85,    84,85,84,85,84,85,84,85,84,85,  84,85,84,85,84,85,84,85,84,85
    .byte 82,83,00,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,00,00,00,    00,00,00,00,00,00,00,00,00,00,  00,00,00,00,89,00,00,00,82,83
    .byte 84,85,00,77,69,69,69,69,69,69,  69,69,69,67,00,00,00,00,00,00,    00,00,00,00,00,00,00,00,00,00,  00,00,00,89,00,00,00,00,84,85
    
    .byte 82,83,00,00,00,00,00,00,82,83,  82,83,82,83,82,83,82,83,82,00,    82,83,82,83,82,83,82,83,82,83,  00,00,00,00,00,00,00,00,82,83
    .byte 84,85,00,00,00,87,00,00,84,85,  00,00,00,00,00,00,00,00,00,00,    00,00,00,00,00,00,00,86,84,85,  00,00,00,00,00,00,00,00,84,85
    .byte 82,83,00,00,00,88,00,00,82,83,  00,00,00,00,00,00,00,00,00,00,    00,00,00,00,00,00,00,86,82,83,  88,00,00,00,00,00,00,00,82,83
    .byte 84,85,00,00,00,88,00,00,84,85,  00,00,00,00,00,00,00,00,00,00,    00,00,00,00,00,00,00,00,84,85,  89,00,00,00,00,00,00,00,84,85
    .byte 82,83,00,00,00,88,00,00,82,83,  87,00,00,00,00,00,00,00,00,00,    00,00,00,00,00,00,00,00,82,83,  89,00,00,00,00,00,00,00,82,83

    .byte 84,85,00,00,00,00,00,00,84,85,  87,00,00,00,00,00,00,00,00,00,    00,00,00,00,00,00,00,00,84,85,  84,85,84,00,84,85,84,85,84,85
    .byte 82,83,00,88,00,00,00,00,82,83,  00,00,00,00,00,00,00,00,00,88,    00,88,00,00,00,00,00,00,82,83,  82,83,82,00,82,83,82,83,82,83
    .byte 84,85,00,00,00,00,00,00,84,85,  00,00,00,00,00,00,00,00,00,00,    00,00,00,00,00,00,00,88,84,85,  00,89,89,00,00,00,00,00,84,85
    .byte 82,83,82,83,82,00,82,83,82,83,  00,00,00,00,00,00,00,00,00,88,    00,88,00,00,00,00,00,88,82,83,  00,00,00,00,00,00,00,00,82,83
    .byte 84,85,84,85,84,00,84,85,84,85,  00,00,00,00,00,00,00,00,00,00,    00,00,00,00,00,00,00,00,84,85,  00,00,00,00,00,00,00,00,84,85
    
    .byte 82,83,00,00,00,00,00,00,82,83,  00,00,00,00,00,00,00,00,00,00,    00,00,00,00,00,00,00,00,82,83,  00,00,00,00,00,00,00,00,82,83
    .byte 84,85,00,00,00,00,00,00,84,85,  00,00,00,00,00,00,00,00,00,00,    00,00,00,00,00,00,00,00,84,85,  89,00,00,00,00,00,00,00,84,85
    .byte 82,83,00,00,00,00,00,00,82,83,  86,00,00,00,00,00,00,00,00,00,    00,00,00,00,00,00,00,00,82,83,  89,00,00,00,00,00,88,00,82,83
    .byte 84,85,00,00,00,87,00,00,84,85,  86,00,00,00,00,00,00,00,00,00,    00,00,00,00,00,00,00,00,84,85,  88,00,00,00,00,87,00,00,84,85
    .byte 82,83,00,00,00,00,87,00,82,83,  82,83,82,83,82,83,82,83,82,83,    82,83,82,83,82,83,82,83,82,83,  00,00,00,00,00,87,00,00,82,83
    
    .byte 84,85,00,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,00,00,00,    00,00,00,00,00,00,00,00,00,00,  00,00,00,00,00,87,00,00,84,85
    .byte 82,83,00,00,00,00,00,00,00,00,  00,00,00,00,00,00,89,00,00,00,    89,00,00,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,00,82,83
    .byte 84,85,00,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,00,00,00,    00,00,00,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,00,84,85
    .byte 82,83,82,83,82,83,82,83,82,83,  82,83,82,83,82,83,82,83,82,83,    82,83,82,83,82,83,82,83,82,83,  82,83,82,83,82,83,82,83,82,83
    .byte 84,85,84,85,84,85,84,85,84,85,  84,85,84,85,84,85,84,85,84,85,    84,85,84,85,84,85,84,85,84,85,  84,85,84,85,84,85,84,85,84,85
    
    *=$4000
    .offs $4000-*
    ;poziom 4

    .byte 00,00,00,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,00,00,00,    00,00,00,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,00,00,00
    .byte 82,83,82,83,82,83,82,83,82,83,  82,83,82,83,82,83,82,83,82,83,    82,83,82,83,82,83,82,83,82,83,  82,83,82,83,82,83,82,83,82,83
    .byte 84,85,84,85,84,85,84,85,84,85,  84,85,84,85,84,85,84,85,84,85,    84,85,84,85,84,85,84,85,84,85,  84,85,84,85,84,85,84,85,84,85
    .byte 82,83,00,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,00,00,00,    00,00,00,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,00,82,83
    .byte 84,85,00,77,69,69,69,69,69,69,  67,00,00,00,00,00,00,00,00,00,    00,00,00,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,00,84,85
    
    .byte 82,83,00,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,00,00,00,    00,00,00,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,00,82,83
    .byte 84,85,00,00,00,00,00,00,00,00,  00,00,87,82,83,00,00,00,00,00,    00,00,00,00,00,82,83,87,00,00,  00,00,00,00,00,00,00,00,84,85
    .byte 82,83,00,00,00,00,00,00,00,00,  00,00,87,84,85,00,00,00,00,00,    00,00,00,00,00,84,85,87,00,00,  00,00,00,00,00,00,00,00,82,83
    .byte 84,85,00,00,00,89,00,00,00,00,  00,00,00,00,86,82,83,00,00,00,    00,00,00,82,83,86,00,00,00,00,  00,00,00,00,00,00,00,00,84,85
    .byte 82,83,00,00,00,89,00,00,00,00,  00,00,00,00,00,84,85,00,00,00,    00,00,00,84,85,00,00,00,00,00,  00,00,00,00,00,00,00,00,82,83

    .byte 84,85,88,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,82,83,00,    00,82,83,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,88,84,85
    .byte 82,83,00,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,84,85,00,    00,84,85,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,00,82,83
    .byte 84,85,88,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,86,86,82,    83,86,86,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,88,84,85
    .byte 82,83,00,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,86,86,84,    85,86,86,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,00,82,83
    .byte 84,85,88,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,82,83,00,    00,82,83,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,88,84,85
    
    .byte 82,83,00,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,84,85,00,    00,84,85,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,00,82,83
    .byte 84,85,00,00,00,00,00,00,00,00,  00,00,00,00,00,82,83,00,00,00,    00,00,00,82,83,00,00,00,00,00,  00,00,00,00,00,00,00,00,84,85
    .byte 82,83,00,00,00,00,00,00,00,00,  00,00,00,00,86,84,85,00,00,00,    00,00,00,84,85,86,00,00,00,00,  00,00,00,00,00,00,00,00,82,83
    .byte 84,85,00,00,00,00,00,00,00,00,  00,00,87,82,83,00,00,00,00,00,    00,00,00,00,00,82,83,87,00,00,  00,00,00,89,89,00,00,00,84,85
    .byte 82,83,00,00,00,00,00,00,00,00,  00,00,87,84,85,00,00,00,00,00,    00,00,00,00,00,84,85,87,00,00,  00,00,00,00,00,00,00,00,82,83
    
    .byte 84,85,00,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,00,00,00,    00,00,00,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,00,84,85
    .byte 82,83,00,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,00,00,00,    00,00,00,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,00,82,83
    .byte 84,85,00,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,00,00,00,    00,00,00,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,00,84,85
    .byte 82,83,82,83,82,83,82,83,82,83,  82,83,82,83,82,83,82,83,82,83,    82,83,82,83,82,83,82,83,82,83,  82,83,82,83,82,83,82,83,82,83
    .byte 84,85,84,85,84,85,84,85,84,85,  84,85,84,85,84,85,84,85,84,85,    84,85,84,85,84,85,84,85,84,85,  84,85,84,85,84,85,84,85,84,85
    
    *=$4400
    .offs $4400-*
    ;poziom 5

    .byte 00,00,00,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,00,00,00,    00,00,00,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,00,00,00
    .byte 82,83,82,83,82,83,82,83,82,83,  82,83,82,83,82,83,82,83,82,83,    82,83,82,83,82,83,82,83,82,83,  82,83,82,83,82,83,82,83,82,83
    .byte 84,85,84,85,84,85,84,85,84,85,  84,85,84,85,84,85,84,85,84,85,    84,85,84,85,84,85,84,85,84,85,  84,85,84,85,84,85,84,85,84,85
    .byte 82,83,00,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,00,00,00,    00,00,00,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,00,82,83
    .byte 84,85,00,77,69,69,69,69,69,69,  69,69,67,00,00,00,00,00,00,00,    00,00,00,00,00,00,00,00,00,00,  00,86,00,00,00,00,00,00,84,85
    
    .byte 82,83,00,00,86,00,00,00,00,00,  00,00,00,00,00,00,00,00,00,00,    00,00,00,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,00,82,83
    .byte 84,85,85,84,85,84,85,84,85,00,  85,84,85,84,85,00,00,00,00,00,    00,00,00,00,00,84,85,84,85,84,  85,00,85,84,85,84,85,84,84,85
    .byte 82,83,00,00,00,00,00,00,00,00,  00,87,87,82,83,00,00,00,00,00,    00,00,00,00,00,82,83,87,87,00,  00,00,00,00,00,00,00,00,82,83
    .byte 84,85,00,00,00,89,00,00,00,00,  00,00,00,00,86,82,83,00,00,00,    00,00,00,82,83,86,00,00,00,00,  00,00,00,00,00,00,00,00,84,85
    .byte 82,83,00,00,00,89,00,00,00,00,  00,00,00,00,00,84,85,00,00,00,    00,00,00,84,85,00,00,00,00,00,  00,00,00,00,00,00,00,00,82,83

    .byte 84,85,88,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,82,83,00,    00,82,83,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,88,84,85
    .byte 82,83,00,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,84,85,00,    00,84,85,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,00,82,83
    .byte 84,85,88,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,86,86,82,    83,86,86,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,88,84,85
    .byte 82,83,00,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,86,86,84,    85,86,86,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,00,82,83
    .byte 84,85,88,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,82,83,00,    00,82,83,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,88,84,85
    
    .byte 82,83,00,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,84,85,00,    00,84,85,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,00,82,83
    .byte 84,85,00,00,00,00,00,00,00,00,  00,00,00,00,00,82,83,00,00,00,    00,00,00,82,83,00,00,00,00,00,  00,00,00,00,00,00,00,00,84,85
    .byte 82,83,00,00,00,00,00,00,00,00,  00,00,00,00,86,84,85,00,00,00,    00,00,00,84,85,86,00,00,00,00,  00,00,00,00,00,00,00,00,82,83
    .byte 84,85,00,00,00,00,00,00,00,00,  00,87,87,84,85,00,00,00,00,00,    00,00,00,00,00,84,85,87,87,00,  00,00,00,89,89,00,00,00,84,85
    .byte 82,83,83,82,00,82,83,82,83,82,  83,82,83,82,83,00,00,00,00,00,    00,00,00,00,00,82,83,82,83,82,  83,82,83,82,83,82,00,82,82,83
    
    .byte 84,85,00,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,00,00,00,    00,00,00,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,00,84,85
    .byte 82,83,00,00,00,00,00,00,00,00,  00,00,86,00,00,00,00,00,00,00,    00,00,00,00,00,00,00,00,00,00,  00,86,00,00,00,00,00,00,82,83
    .byte 84,85,00,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,00,00,00,    00,00,00,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,00,84,85
    .byte 82,83,82,83,82,83,82,83,82,83,  82,83,82,83,82,83,82,83,82,83,    82,83,82,83,82,83,82,83,82,83,  82,83,82,83,82,83,82,83,82,83
    .byte 84,85,84,85,84,85,84,85,84,85,  84,85,84,85,84,85,84,85,84,85,    84,85,84,85,84,85,84,85,84,85,  84,85,84,85,84,85,84,85,84,85
    
    *=$4800
    .offs $4800-*
    ;poziom 6

    .byte 00,00,00,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,00,00,00,    00,00,00,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,00,00,00
    .byte 82,83,82,83,82,83,82,83,82,83,  82,83,82,83,82,83,82,83,82,83,    82,83,82,83,82,83,82,83,82,83,  82,83,82,83,82,83,82,83,82,83
    .byte 84,85,84,85,84,85,84,85,84,85,  84,85,84,85,84,85,84,85,84,85,    84,85,84,85,84,85,84,85,84,85,  84,85,84,85,84,85,84,85,84,85
    .byte 82,83,00,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,00,00,00,    00,00,00,00,00,00,00,00,00,00,  00,00,00,00,00,00,88,88,82,83
    .byte 84,85,00,77,69,69,69,69,69,69,  67,00,00,00,00,00,00,00,00,00,    00,00,00,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,00,84,85
    
    .byte 82,83,00,00,82,83,82,83,82,83,  82,83,82,83,82,83,82,83,82,00,    82,83,82,83,82,83,82,83,82,83,  82,83,82,83,82,83,00,00,82,83
    .byte 84,85,00,00,84,85,84,85,84,85,  84,85,84,85,84,85,84,85,84,00,    84,85,84,85,84,85,84,85,84,85,  84,85,84,85,84,85,00,00,84,85
    .byte 82,83,00,00,82,83,87,00,00,00,  00,00,00,00,00,00,00,00,00,00,    00,00,00,00,00,00,00,00,00,00,  00,00,87,00,82,83,00,00,82,83
    .byte 84,85,00,00,84,85,00,00,00,00,  00,88,00,00,00,00,00,00,00,00,    00,00,00,88,00,00,00,00,00,00,  00,00,00,00,84,85,00,00,84,85
    .byte 82,83,00,00,82,83,00,87,82,83,  82,83,82,83,82,83,82,83,82,83,    82,83,82,83,82,83,82,83,82,83,  82,83,00,87,82,83,00,00,82,83

    .byte 84,85,00,00,84,85,00,00,84,85,  00,86,00,00,00,00,00,00,00,00,    00,00,00,00,00,00,00,00,00,00,  84,85,00,00,84,85,00,00,84,85
    .byte 82,83,00,00,82,83,87,00,82,83,  00,00,00,00,00,00,00,00,00,00,    00,00,00,00,00,00,00,86,00,00,  82,83,87,00,82,83,00,00,82,83
    .byte 84,85,87,00,84,85,00,00,84,85,  00,00,00,00,00,00,00,00,00,86,    00,00,00,00,00,00,00,00,00,00,  84,85,00,00,84,85,00,00,84,85
    .byte 82,83,87,00,82,83,00,87,00,00,  00,00,00,00,00,00,00,00,00,86,    86,00,00,00,00,00,00,00,00,00,  00,00,00,87,82,83,00,00,82,83
    .byte 84,85,87,00,84,85,00,00,84,85,  00,86,00,00,00,00,00,00,00,00,    86,00,00,00,00,00,00,00,00,00,  84,85,00,00,84,85,00,00,84,85
    
    .byte 82,83,00,87,82,83,87,00,82,83,  00,00,00,00,00,00,00,00,00,00,    00,00,00,00,00,00,00,86,00,00,  82,83,87,00,82,83,00,00,82,83
    .byte 84,85,00,87,84,85,00,00,84,85,  84,85,84,85,84,85,84,85,84,85,    84,85,84,85,84,85,84,85,84,85,  84,85,00,00,84,85,00,87,84,85
    .byte 82,83,00,87,82,83,00,87,00,00,  00,00,00,00,00,00,00,00,00,00,    00,00,00,00,00,00,00,00,00,00,  00,00,00,87,82,83,00,87,82,83
    .byte 84,85,00,00,84,85,00,00,00,00,  00,00,00,00,00,00,00,00,00,00,    00,00,00,00,00,00,00,00,00,00,  00,00,00,00,84,85,00,87,84,85
    .byte 82,83,00,00,82,83,82,83,82,83,  82,83,82,83,82,83,82,83,82,00,    82,83,82,83,82,83,82,83,82,83,  82,83,82,83,82,83,87,00,82,83
    
    .byte 84,85,00,00,84,85,84,85,84,85,  84,85,84,85,84,85,84,85,84,00,    84,85,84,85,84,85,84,85,84,85,  84,85,84,85,84,85,87,00,84,85
    .byte 82,83,86,86,00,00,00,00,00,00,  00,00,00,00,00,00,00,00,00,00,    00,00,00,00,00,00,00,00,00,00,  00,00,00,00,00,00,87,00,82,83
    .byte 84,85,86,86,00,00,00,00,00,00,  00,00,00,00,00,00,00,00,00,00,    00,00,00,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,00,84,85
    .byte 82,83,82,83,82,83,82,83,82,83,  82,83,82,83,82,83,82,83,82,83,    82,83,82,83,82,83,82,83,82,83,  82,83,82,83,82,83,82,83,82,83
    .byte 84,85,84,85,84,85,84,85,84,85,  84,85,84,85,84,85,84,85,84,85,    84,85,84,85,84,85,84,85,84,85,  84,85,84,85,84,85,84,85,84,85
    
    *=$4c00
    .offs $4c00-*
    ;poziom 7

    .byte 00,00,00,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,00,00,00,    00,00,00,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,00,00,00
    .byte 82,83,82,83,82,83,82,83,82,83,  82,83,82,83,82,83,82,83,82,83,    82,83,82,83,82,83,82,83,82,83,  82,83,82,83,82,83,82,83,82,83
    .byte 84,85,84,85,84,85,84,85,84,85,  84,85,84,85,84,85,84,85,84,85,    84,85,84,85,84,85,84,85,84,85,  84,85,84,85,84,85,84,85,84,85
    .byte 82,83,00,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,00,00,00,    00,00,00,00,00,00,00,00,00,00,  00,00,00,00,00,00,88,88,82,83
    .byte 84,85,00,77,69,69,69,69,69,69,  69,69,69,67,00,00,00,00,00,00,    00,00,00,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,00,84,85
    
    .byte 82,83,00,00,82,83,82,83,82,83,  82,83,82,83,82,83,82,83,82,00,    82,83,82,83,82,83,82,83,82,83,  82,83,82,83,82,83,00,00,82,83
    .byte 84,85,00,00,84,85,84,85,84,85,  84,85,89,89,89,89,84,85,84,00,    84,85,84,89,89,89,89,85,84,85,  84,85,84,85,84,85,00,00,84,85
    .byte 82,83,00,00,82,83,87,00,00,00,  00,00,00,00,00,00,00,00,00,00,    00,00,00,00,00,00,00,00,00,00,  00,00,87,00,82,83,00,00,82,83
    .byte 84,85,00,00,84,85,00,00,00,00,  00,88,00,00,00,00,00,00,00,00,    00,00,00,88,00,00,00,00,00,00,  00,00,00,00,84,85,00,00,84,85
    .byte 82,83,00,00,82,83,00,87,82,83,  82,83,82,83,82,83,82,83,82,83,    82,83,82,83,82,83,82,83,82,83,  82,83,00,87,82,83,00,00,82,83

    .byte 84,85,00,00,84,85,00,00,84,85,  00,86,00,00,00,00,00,00,00,00,    00,00,00,00,00,00,00,00,00,00,  84,85,00,00,84,85,00,00,84,85
    .byte 82,83,00,00,82,83,87,00,82,83,  00,00,00,00,00,00,00,00,00,00,    00,00,00,00,00,00,00,86,00,00,  82,83,87,00,82,83,00,00,82,83
    .byte 84,85,87,00,84,85,00,00,84,85,  00,00,00,00,00,00,00,00,00,86,    00,00,00,00,00,00,00,00,00,00,  84,85,00,00,84,85,00,00,84,85
    .byte 82,83,87,00,82,83,00,87,00,00,  00,00,00,00,00,00,00,00,00,86,    86,00,00,00,00,00,00,00,00,00,  00,00,00,87,82,83,00,00,82,83
    .byte 84,85,87,00,84,85,00,00,84,85,  00,86,00,00,00,00,00,00,00,00,    86,00,00,00,00,00,00,00,00,00,  84,85,00,00,84,85,00,00,84,85
    
    .byte 82,83,00,87,82,83,87,00,82,83,  00,00,00,00,00,00,00,00,00,00,    00,00,00,00,00,00,00,86,00,00,  82,83,87,00,82,83,00,00,82,83
    .byte 84,85,00,87,84,85,00,00,84,85,  84,85,84,85,84,85,84,85,84,85,    84,85,84,85,84,85,84,85,84,85,  84,85,00,00,84,85,00,87,84,85
    .byte 82,83,00,87,82,83,00,87,00,00,  00,00,00,00,00,00,00,00,00,00,    00,00,00,00,00,00,00,00,00,00,  00,00,00,87,82,83,00,87,82,83
    .byte 84,85,00,00,84,85,00,00,00,00,  00,00,00,00,00,00,00,00,00,00,    00,00,00,00,00,00,00,00,00,00,  00,00,00,00,84,85,00,87,84,85
    .byte 82,83,00,00,82,83,82,83,82,83,  82,88,88,88,82,83,82,83,82,00,    82,88,88,88,82,83,82,83,82,83,  82,83,82,83,82,83,87,00,82,83
    
    .byte 84,85,00,00,84,85,84,85,84,85,  84,85,84,85,84,85,84,85,84,00,    84,85,84,85,84,85,84,85,84,85,  84,85,84,85,84,85,87,00,84,85
    .byte 82,83,86,86,00,00,00,00,00,00,  00,00,00,00,00,00,00,00,00,00,    00,00,00,00,00,00,00,00,00,00,  00,00,00,00,00,00,87,00,82,83
    .byte 84,85,86,86,00,00,00,00,00,00,  00,00,00,00,00,00,00,00,00,00,    00,00,00,00,00,00,00,00,00,00,  00,00,00,00,00,00,00,00,84,85
    .byte 82,83,82,83,82,83,82,83,82,83,  82,83,82,83,82,83,82,83,82,83,    82,83,82,83,82,83,82,83,82,83,  82,83,82,83,82,83,82,83,82,83
    .byte 84,85,84,85,84,85,84,85,84,85,  84,85,84,85,84,85,84,85,84,85,    84,85,84,85,84,85,84,85,84,85,  84,85,84,85,84,85,84,85,84,85
    
