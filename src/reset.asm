;===============================================================================
; Reset CPU for the MEZW65C_RAM add-on board
;
;    Target: MEZW65C_RAM
;    Written by Akihito Honda (Aki.h @akih_san)
;    https://twitter.com/akih_san
;    https://github.com/akih-san
;    Date. 2024.8.02
;
; Copyright (c) 2024 Akihito Honda
;
; Released under the MIT license
;
; Permission is hereby granted, free of charge, to any person obtaining a copy of this
; software and associated documentation files (the �gSoftware�h), to deal in the Software
; without restriction, including without limitation the rights to use, copy, modify, merge,
; publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons
; to whom the Software is furnished to do so, subject to the following conditions:
;
; The above copyright notice and this permission notice shall be included in all copies or
; substantial portions of the Software.
; 
; THE SOFTWARE IS PROVIDED �gAS IS�h, WITHOUT WARRANTY OF ANY KIND, EXPRESS
; OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
; MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
; NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
; BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
; ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
; CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
; SOFTWARE.
;===============================================================================

                pw      132
                inclist on

                chip    65816

	.code
	ORG	$FFF0

RESET:
	sec
	xce	; if cpu=W65C02 then xce = nop operation
NMIBRK:
IRQBRK:
	stp	; stop CPU


	ORG	$FFFA

	FDB	NMIBRK		; NMI

	FDB	RESET		; RESET

	FDB	IRQBRK		; IRQ/BRK

	END