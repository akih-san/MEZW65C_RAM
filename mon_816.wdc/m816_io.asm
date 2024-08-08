;===============================================================================
; Basic Vector Handling for the MEZW65C_RAM add-on board
;
;    Target: MEZW65C_RAM
;    Written by Akihito Honda (Aki.h @akih_san)
;    https://twitter.com/akih_san
;    https://github.com/akih-san
;    Date. 2024.7.09
;
; Copyright (c) 2024 Akihito Honda
;
; Released under the MIT license
;
; Permission is hereby granted, free of charge, to any person obtaining a copy of this
; software and associated documentation files (the ÅgSoftwareÅh), to deal in the Software
; without restriction, including without limitation the rights to use, copy, modify, merge,
; publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons
; to whom the Software is furnished to do so, subject to the following conditions:
;
; The above copyright notice and this permission notice shall be included in all copies or
; substantial portions of the Software.
; 
; THE SOFTWARE IS PROVIDED ÅgAS ISÅh, WITHOUT WARRANTY OF ANY KIND, EXPRESS
; OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
; MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
; NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
; BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
; ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
; CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
; SOFTWARE.
; 
; <Original sorce code>
; w65c816sxb.asm
; https://github.com/andrew-jacobs/w65c816sxb-hacker
; Thanks all.
;-------------------------------------------------------------------------------

                pw      132
                inclist on

                chip    65816

                include "w65c816.inc"

;===============================================================================
; Data Areas
;-------------------------------------------------------------------------------

                page0

                org     $18

; PIC18F47QXX I/F
UREQ_COM	ds	1	; unimon CONIN/CONOUT request command
UNI_CHR		ds	1	; charcter (CONIN/CONOUT) or number of strings
CREQ_COM	ds	1	; unimon CONIN/CONOUT request command
CBI_CHR		ds	1	; charcter (CONIN/CONOUT) or number of strings
disk_drive	ds	1	;
disk_track	ds	2	;
disk_sector	ds	2	;
data_adr	ds	2	;
bank		ds	1	;
reserve		ds	1	;


;===============================================================================
; Power On Reset
;-------------------------------------------------------------------------------

cpu_id          equ	$00	; memory address $0000 is written CPU ID by PIC

                code
                extern  Start
                longi   off
                longa   off
RESET:
                sei                             ; Stop interrupts
                ldx     #$ff                    ; Reset the stack
                txs

; check W65C816 CPU ?

                lda	cpu_id			; get cpu id from PIC 0:W65C02, 1:W65C816S
                bne	ok_start

                ldx	#0
msg_lop:
                lda	haltm,x
                beq	stop_prg
                jsr	UartTx			; print error message
                inx
                bra	msg_lop

stop_prg:
                sei
                stp				; STOP

ok_start:
                native                          ; Switch to native mode
                jmp     Start                   ; Jump to the application start

;===============================================================================
; Interrupt Handlers
;-------------------------------------------------------------------------------

; Handle IRQ and BRK interrupts in emulation mode.

IRQBRK:
                bra     $                       ; Loop forever

; Handle NMI interrupts in emulation mode.

NMIRQ:
                bra     $                       ; Loop forever

;-------------------------------------------------------------------------------

; Handle IRQ interrupts in native mode.

IRQ:
                bra     $                       ; Loop forever

; Handle IRQ interrupts in native mode.

BRK:
                bra     $                       ; Loop forever

; Handle IRQ interrupts in native mode.

NMI:
                bra     $                       ; Loop forever

;-------------------------------------------------------------------------------

; COP and ABORT interrupts are not handled.

COP:
                bra     $                       ; Loop forever

ABORT:
                bra     $                       ; Loop forever

;===============================================================================
;
;  	Console Driver
;
;CONIN_REQ	EQU	0x01
;CONOUT_REQ	EQU	0x02
;CONST_REQ	EQU	0x03
;STROUT_REQ	EQU	0x04
;  ---- request command to PIC
; UREQ_COM = 1 ; CONIN  : return char in UNI_CHR
;          = 2 ; CONOUT : UNI_CHR = output char
;          = 3 ; CONST  : return status in UNI_CHR
;                       : ( 0: no key, 1 : key exist )
;          = 4 ; STROUT : string address = (PTRSAV, PTRSAV_SEG)
;
;UREQ_COM	rmb	1	; unimon CONIN/CONOUT request command
;UNI_CHR	rmb	1	; charcter (CONIN/CONOUT) or number of strings
;STR_adr	rmb	2	; string address
;-------------------------------------------------------------------------------

; PIC function code

CONIN_REQ	EQU	$01
CONOUT_REQ	EQU	$02
CONST_REQ	EQU	$03

INIT:
                ; clear Reqest Parameter Block
                lda	#0
                sta	UREQ_COM
                sta	CREQ_COM
                sta	bank
                sta	reserve
                RTS

wup_pic:
                sta	UREQ_COM
                wai			; RDY = 0, wait /IRQ detect
;                nop
;                nop
;                nop
;                nop
;                nop
;                nop
;                nop
;                nop

                lda	UNI_CHR
                RTS

                public  UartRx

UartRx:
                php			; Save register sizes
                short_a			; Make A 8-bits
                lda	#CONIN_REQ
                jsr	wup_pic
                plp			; Restore register sizes
                rts


; Check if the receive buffer contains any data and return C=1 if there is
; some.

                public  UartRxTest
UartRxTest:
                pha
                php
                short_a			; Make A 8-bits
                lda	#CONST_REQ
                jsr	wup_pic
                plp
                ror	a
                pla
                rts

                public  UartTx
UartTx:
                pha
                php			; Save register sizes
                short_a			; Make A 8-bits
                sta	UNI_CHR		; set char
                lda	#CONOUT_REQ
                jsr	wup_pic
                plp			; Restore register sizes
                pla
                rts

LF              equ     $0a
CR              equ     $0d

haltm:
                db	CR,LF,"No W65C816S is detected!",CR, LF
		db	"CPU HALT!!", CR, LF, 0

;===============================================================================
; Reset Vectors
;-------------------------------------------------------------------------------

Vectors         section offset $ffe0

                ds      4                       ; Reserved
                dw      COP                     ; $FFE4 - COP(816)
                dw      BRK                     ; $FFE6 - BRK(816)
                dw      ABORT                   ; $FFE8 - ABORT(816)
                dw      NMI                     ; $FFEA - NMI(816)
                ds      2                       ; Reserved
                dw      IRQ                     ; $FFEE - IRQ(816)

                ds      4
                dw      COP                     ; $FFF4 - COP(C02)
                ds      2                       ; $Reserved
                dw      ABORT                   ; $FFF8 - ABORT(C02)
                dw      NMIRQ                   ; $FFFA - NMI(C02)
                dw      RESET                   ; $FFFC - RESET(C02)
                dw      IRQBRK                  ; $FFFE - IRQBRK(C02)

                ends

                end
