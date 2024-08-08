
; minimal monitor for EhBASIC and 6502 simulator V1.05

; To run EhBASIC on the simulator load and assemble [F7] this file, start the simulator
; running [F6] then start the code with the RESET [CTRL][SHIFT]R. Just selecting RUN
; will do nothing, you'll still have to do a reset to run the code.

		pl	0
                pw      132
                inclist on

        .include "basic.asm"

; put the IRQ and MNI code in RAM so that it can be changed

IRQ_vec equ VEC_SV+2              ; IRQ code vector
NMI_vec equ IRQ_vec+$0A   ; NMI code vector

; now the code. all this does is set up the vectors and interrupt code
; and wait for the user to select [C]old or [W]arm start. nothing else
; fits in less than 128 bytes


;        .dsb    $FF60 - *, $FF
        org $FF60
; reset vector points here

RES_vec
        SEI
        CLD                             ; clear decimal mode
        LDX     #$FF                    ; empty stack
        TXS                             ; set the stack

        jsr     INIT_RPB        ; clear PIC request command table

; set up vectors and interrupt code, copy them to page 2

        LDY     #END_CODE-LAB_vec       ; set index/count
LAB_stlp
        LDA     LAB_vec-1,Y             ; get byte from interrupt code
        STA     VEC_IN-1,Y              ; save to RAM
        DEY                             ; decrement index/count
        BNE     LAB_stlp                ; loop if more to do

; now do the signon message, Y = $00 here


LAB_signon
        LDA     LAB_mess,Y              ; get byte from sign on message
        BEQ     LAB_nokey               ; exit loop if done

        JSR     CONOUT                  ; output character
        INY                             ; increment index
        BNE     LAB_signon              ; loop, branch always

LAB_nokey
        JSR     CONIN                   ; call scan input device
        BCC     LAB_nokey               ; loop if no key

        AND     #$DF                    ; mask xx0x xxxx, ensure upper case
        CMP     #'W'                    ; compare with [W]arm start
        BEQ     LAB_dowarm              ; branch if [W]arm start

        CMP     #'C'                    ; compare with [C]old start
        BNE     RES_vec                 ; loop if not [C]old start

        JMP     LAB_COLD                ; do EhBASIC cold start

LAB_dowarm
        JMP     LAB_WARM                ; do EhBASIC warm start

;;;
;;;     Console Driver
;;;

CONIN_REQ     equ       $01
CONOUT_REQ    equ       $02
CONST_REQ     equ       $03
STROUT_REQ    equ       $04

UREQ_COM      equ       $18     ; CONIN/CONOUT request command (SYS)
CREQ_COM      equ       $1A     ; CONIN/CONOUT request command (User)
CBI_CHR       equ       $1B     ; charcter (CONIN/CONOUT) or number of strings

;  ---- request command to PIC
; UREQ_COM = 1 ; CONIN  : return char in UNI_CHR
;          = 2 ; CONOUT : UNI_CHR = output char
;          = 3 ; CONST  : return status in UNI_CHR
;                       : ( 0: no key, 1 : key exist )
;
; PIC18F47QXX I/F( zero page )
; adr :
;  18 : UREQ_COM        rmb     1       ; unimon CONIN/CONOUT request command
;  19 : UNI_CHR         rmb     1       ; charcter (CONIN/CONOUT) or number of strings
;  1A : CREQ_COM        rmb     1       ; unimon CONIN/CONOUT request command
;  1B : CBI_CHR         rmb     1       ; charcter (CONIN/CONOUT) or number of strings


INIT_RPB
        ; clear Reqest Parameter Block
        lda     #0
        sta     UREQ_COM
        sta     CREQ_COM
no_load                         ; empty load vector for EhBASIC
no_save                         ; empty save vector for EhBASIC
        RTS

no_key
        clc
        RTS

CONIN
        lda     #CONST_REQ
        jsr     wup_pic
        beq     no_key

        lda     #CONIN_REQ

wup_pic
        sta     CREQ_COM
        wai                     ; RDY = 0, wait /IRQ detect
;        nop
;        nop
;        nop
;        nop
;        nop
;        nop
;        nop
;        nop

        lda     CBI_CHR
        sec
        RTS

CONOUT
        sta     CBI_CHR         ; set char
        pha
        lda     #CONOUT_REQ
        jsr     wup_pic
        pla
        rts

; vector tables

LAB_vec
        .word   CONIN           ; byte in from simulated ACIA
        .word   CONOUT          ; byte out to simulated ACIA
        .word   no_load         ; null load vector for EhBASIC
        .word   no_save         ; null save vector for EhBASIC

; EhBASIC IRQ support

IRQ_CODE
        PHA                     ; save A
        LDA     IrqBase         ; get the IRQ flag byte
        LSR                     ; shift the set b7 to b6, and on down ...
        ORA     IrqBase         ; OR the original back in
        STA     IrqBase         ; save the new IRQ flag byte
        PLA                             ; restore A
        RTI

; EhBASIC NMI support

NMI_CODE
        PHA                     ; save A
        LDA     NmiBase         ; get the NMI flag byte
        LSR                     ; shift the set b7 to b6, and on down ...
        ORA     NmiBase         ; OR the original back in
        STA     NmiBase         ; save the new NMI flag byte
        PLA                     ; restore A
        RTI

END_CODE

LAB_mess
        .byte   $0D,$0A,"6502 EhBASIC [C]old/[W]arm ?",$00
                                        ; sign on string

; system vectors

;        .dsb    $FFFA - *, $FF
        org $FFFA

        .word   NMI_vec         ; NMI vector
        .word   RES_vec         ; RESET vector
        .word   IRQ_vec         ; IRQ vector

