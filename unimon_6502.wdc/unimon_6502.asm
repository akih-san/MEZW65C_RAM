;;;
;;; Universal Monitor 6502
;;;   Copyright (C) 2019 Haruo Asano
;;;

		pl	0
                pw      132
;                inclist on
;;;
;;; Universal Monitor 6502 config file (sample)
;;;

;;;
;;; Memory
;;;

PRG_B	EQU	$F800
ENTRY	EQU	$FF80		; Entry point
	
WORK_B	EQU	$0018		; Must fit in ZERO page

STACK	EQU	$01FF

BUFLEN	EQU	16		; Buffer length ( 16 or above )
cpu_id	equ	$00		; memory address $0000 is written CPU ID by PIC

; PIC function code

CONIN_REQ	EQU	$01
CONOUT_REQ	EQU	$02
CONST_REQ	EQU	$03

;;; Constants
CR	EQU	$0D
LF	EQU	$0A
BS	EQU	$08
DEL	EQU	$7F
NULL	EQU	$00

;--------------------------------------
;ZERO page
;--------------------------------------
	;;
	;; Work Area
	;;

	.page0
	ORG	WORK_B

; PIC18F47QXX I/F
UREQ_COM	rmb	1	; unimon CONIN/CONOUT request command
UNI_CHR		rmb	1	; charcter (CONIN/CONOUT) or number of strings
CREQ_COM	rmb	1	; unimon CONIN/CONOUT request command
CBI_CHR		rmb	1	; charcter (CONIN/CONOUT) or number of strings
disk_drive	rmb	1	;
disk_track	rmb	2	;
disk_sector	rmb	2	;
data_adr	rmb	2	;
bank		rmb	1	;
reserve		rmb	1	;

INBUF	RMB	BUFLEN		; Line input buffer
DSADDR	RMB	2		; Dump start address
DEADDR	RMB	2		; Dump end address
DSTATE	RMB	1		; Dump state
GADDR	RMB	2		; Go address
SADDR	RMB	2		; Set address
HEXMOD	RMB	1		; HEX file mode
RECTYP	RMB	1		; Record type
PSPEC	RMB	1		; Processor spec.

REGA	RMB	1		; Accumulator A
REGX	RMB	1		; Index register X
REGY	RMB	1		; Index register Y
REGSP	RMB	1		; Stack pointer SP
REGPC	RMB	2		; Program counter PC
REGPSR	RMB	1		; Processor status register PSR

REGSIZ	RMB	1		; Register size
	
DMPPT	RMB	2
CKSUM	RMB	1		; Checksum
HITMP	RMB	1		; Temporary (used in HEXIN)

PT0	RMB	2		; Generic Pointer 0
PT1	RMB	2		; Generic Pointer 1
CNT	RMB	1		; Generic Counter

;;;
;;; Program area
;;;	
	.code
	ORG	PRG_B

CSTART	equ	*
	sei			; disable interrupt
	LDX	#STACK & $ff
	TXS
	JSR	INIT

	LDA	#$00
	STA	DSADDR
	STA	DSADDR+1
	STA	SADDR
	STA	SADDR+1
	STA	GADDR
	STA	GADDR+1
	STA	PSPEC
	LDA	#'S'
	STA	HEXMOD

	LDA	#$00
	STA	REGA
	STA	REGX
	STA	REGY
	STA	REGPC
	STA	REGPC+1
	STA	REGPSR
	TSX
	STX	REGSP
	
	;; Opening message
;	CLI
	LDA	#$FF&OPNMSG
	STA	PT0
	LDA	#OPNMSG>>8
	STA	PT0+1
	JSR	STROUT

	; check CPU
	lda	cpu_id			; get cpu id from PIC 0:W65C02, 1:W65C816S
	beq	ok_6502

	LDA	#$FF&IMW816
	STA	PT0
	LDA	#IMW816>>8
	STA	PT0+1
	LDA	#$06

	STA	PSPEC
	JSR	STROUT
	bra	WSTART

ok_6502
	LDA	#$FF&IMR65C
	STA	PT0
	LDA	#IMR65C>>8
	STA	PT0+1
	LDA	#$04

	STA	PSPEC
	JSR	STROUT

WSTART
;	CLI
	LDA	#$FF&PROMPT
	STA	PT0
	LDA	#PROMPT>>8
	STA	PT0+1
	JSR	STROUT
	JSR	GETLIN
	LDX	#0
	JSR	SKIPSP
	JSR	UPPER
	CMP	#0
	BEQ	WSTART

	CMP	#'D'
	BNE	M00
	JMP	DUMP
M00
	CMP	#'G'
	BNE	M01
	JMP	GO
M01
	CMP	#'S'
	BNE	M02
	JMP	SETM
M02
	CMP	#'L'
	BNE	M03
	JMP	LOADH
M03
	
	CMP	#'R'
	BNE	M05
	JMP	REG
M05	
ERR
	LDA	#$FF&ERRMSG
	STA	PT0
	LDA	#ERRMSG>>8
	STA	PT0+1
	JSR	STROUT
	JMP	WSTART

;;;
;;; Dump memory
;;;
DUMP
	INX
	JSR	SKIPSP
	JSR	RDHEX
	LDA	CNT
	BNE	DP0

	;; No arg.
	JSR	SKIPSP
	LDA	INBUF,X
	BNE	ERR
DP00	
	LDA	DSADDR
	CLC
	ADC	#128
	STA	DEADDR
	LDA	DSADDR+1
	ADC	#0
	STA	DEADDR+1
	JMP	DPM

	;; 1st arg. found
DP0
	LDA	PT1
	STA	DSADDR
	LDA	PT1+1
	STA	DSADDR+1
	JSR	SKIPSP
	LDA	INBUF,X
	CMP	#','
	BEQ	DP1
	CMP	#0
	BNE	ERR
	;; No 2nd arg.
	JMP	DP00
DP1
	INX
	JSR	SKIPSP
	JSR	RDHEX
	JSR	SKIPSP
	LDA	CNT
	BEQ	ERR
	LDA	INBUF,X
	BNE	ERR
	LDA	PT1
	SEC
	ADC	#0
	STA	DEADDR
	LDA	PT1+1
	ADC	#0
	STA	DEADDR+1

	;; DUMP main
DPM	
	LDA	DSADDR
	AND	#$F0
	STA	PT1
	LDA	DSADDR+1
	STA	PT1+1
	LDA	#0
	STA	DSTATE
DPM0
	JSR	DPL
	LDA	PT1
	CLC
	ADC	#16
	STA	PT1
	LDA	PT1+1
	ADC	#0
	STA	PT1+1
	JSR	CONST
	BNE	DPM1
	LDA	DSTATE
	CMP	#2
	BCC	DPM0
	LDA	DEADDR
	STA	DSADDR
	LDA	DEADDR+1
	STA	DSADDR+1
	JMP	WSTART
DPM1
	LDA	PT1
	STA	DSADDR
	LDA	PT1+1
	STA	DSADDR+1
	JSR	CONIN
	JMP	WSTART

	;; Dump line
DPL
	LDA	PT1+1
	JSR	HEXOUT2
	LDA	PT1
	JSR	HEXOUT2
	LDA	#$FF&DSEP0
	STA	PT0
	LDA	#DSEP0>>8
	STA	PT0+1
	JSR	STROUT
	LDX	#0
	LDY	#0
DPL0
	JSR	DPB
	CPX	#16
	BNE	DPL0

	LDA	#$FF&DSEP1
	STA	PT0
	LDA	#DSEP1>>8
	STA	PT0+1
	JSR	STROUT

	;; Print ASCII area
	LDX	#0
DPL1
	LDA	INBUF,X
	CMP	#' '
	BCC	DPL2
	CMP	#$7F
	BCS	DPL2
	JSR	CONOUT
	JMP	DPL3
DPL2
	LDA	#'.'
	JSR	CONOUT
DPL3
	INX
	CPX	#16
	BNE	DPL1
	JMP	CRLF

	;; Dump byte
DPB
	LDA	#' '
	JSR	CONOUT
	LDA	DSTATE
	BNE	DPB2
	;; Dump state 0
	TYA
	SEC
	SBC	DSADDR
	AND	#$0F
	BEQ	DPB1
	;; Still 0 or 2
DPB0
	LDA	#' '
	STA	INBUF,X
	JSR	CONOUT
	LDA	#' '
	JSR	CONOUT
	INX
	INY
	RTS
	;; Found start address
DPB1
	LDA	#1
	STA	DSTATE
DPB2
	LDA	DSTATE
	CMP	#1
	BNE	DPB0
	;; Dump state 1
	LDA	(PT1),Y
	STA	INBUF,X
	JSR	HEXOUT2
	INX
	INY
	TYA
	CLC
	ADC	PT1
	STA	PT0
	LDA	PT1+1
	ADC	#0
	STA	PT0+1
	LDA	PT0
	CMP	DEADDR
	BNE	DPBE
	LDA	PT0+1
	CMP	DEADDR+1
	BNE	DPBE
	;; Found end address
	LDA	#2
	STA	DSTATE
DPBE
	RTS

;;;
;;;  Go address
;;;
GO
	INX
	JSR	SKIPSP
	JSR	RDHEX
	LDA	INBUF,X
	BEQ	G00
	JMP	ERR
G00
	LDA	CNT
	BEQ	G0

	LDA	PT1
	STA	REGPC
	LDA	PT1+1
	STA	REGPC+1
G0
	LDX	REGSP
	TXS			; SP
	LDA	REGPC+1
	PHA			; PC(H)
	LDA	REGPC
	PHA			; PC(L)
	LDA	REGPSR
	PHA			; PSR
	LDA	REGA
	LDX	REGX
	LDY	REGY
	RTI

;;;
;;; Set memory
;;;
SETM
	INX
	JSR	SKIPSP
	JSR	RDHEX
	JSR	SKIPSP
	LDA	INBUF,X
	BEQ	SM0
	JMP	ERR
SM0
	LDA	CNT
	BEQ	SM1
	LDA	PT1
	STA	SADDR
	LDA	PT1+1
	STA	SADDR+1
SM1
	LDA	SADDR+1
	JSR	HEXOUT2
	LDA	SADDR
	JSR	HEXOUT2
	LDA	#$FF&DSEP1
	STA	PT0
	LDA	#DSEP1>>8
	STA	PT0+1
	JSR	STROUT
	LDY	#0
	LDA	(SADDR),Y
	JSR	HEXOUT2
	LDA	#' '
	JSR	CONOUT
	JSR	GETLIN
	LDX	#0
	JSR	SKIPSP
	LDA	INBUF,X
	BNE	SM2
SM10	
	;; Empty (Increment address)
	LDA	SADDR
	CLC
	ADC	#1
	STA	SADDR
	LDA	SADDR+1
	ADC	#0
	STA	SADDR+1
	JMP	SM1
SM2
	CMP	#'-'
	BNE	SM3
	;; '-' (Decrement address)
	LDA	SADDR
	SEC
	SBC	#1
	STA	SADDR
	LDA	SADDR+1
	SBC	#0
	STA	SADDR+1
	JMP	SM1
SM3
	CMP	#'.'
	BNE	SM4
	;; '.' (Quit)
	JMP	WSTART
SM4
	JSR	RDHEX
	LDA	CNT
	BNE	SM40
SMER
	JMP	ERR
SM40
	LDA	PT1
	LDY	#0
	STA	(SADDR),Y
	JMP	SM10

;;;
;;; LOAD HEX file
;;;
LOADH
	INX
	JSR	SKIPSP
	JSR	RDHEX
	JSR	SKIPSP
	LDA	INBUF,X
	BNE	SMER
LH0
	JSR	CONIN
	JSR	UPPER
	CMP	#'S'
	BEQ	LHS0
LH1a
	CMP	#NULL
;	CMP	#''
	BEQ	LHI0
LH2
	;; Skip to EOL
	CMP	#CR
	BEQ	LH0
	CMP	#LF
	BEQ	LH0
LH3
	JSR	CONIN
	JMP	LH2

LHI0
	JSR	HEXIN
	STA	CKSUM
	STA	CNT		; Length

	JSR	HEXIN
	STA	DMPPT+1		; Address H
	CLC
	ADC	CKSUM
	STA	CKSUM

	JSR	HEXIN
	STA	DMPPT		; Address L
	CLC
	ADC	CKSUM
	STA	CKSUM

	;; Add offset
	LDA	DMPPT
	CLC
	ADC	PT1
	STA	DMPPT
	LDA	DMPPT+1
	ADC	PT1+1
	STA	DMPPT+1
	LDY	#0
	
	JSR	HEXIN
	STA	RECTYP		; Record Type
	CLC
	ADC	CKSUM
	STA	CKSUM

	LDA	CNT
	BEQ	LHI3
LHI1
	JSR	HEXIN
	PHA
	CLC
	ADC	CKSUM
	STA	CKSUM

	LDA	RECTYP
	BNE	LHI2

	PLA
	STA	(DMPPT),Y
	INY
	PHA			; Dummy, better than JMP to skip next PLA
LHI2
	PLA
	DEC	CNT
	BNE	LHI1
LHI3
	JSR	HEXIN
	CLC
	ADC	CKSUM
	BNE	LHIE		; Checksum error
	LDA	RECTYP
	BEQ	LH3
	JMP	WSTART
LHIE
	LDA	#$FF&IHEMSG
	STA	PT0
	LDA	#IHEMSG>>8
	STA	PT0+1
	JSR	STROUT
	JMP	WSTART

LHS0	
	JSR	CONIN
	STA	RECTYP		; Record Type

	JSR	HEXIN
	STA	CNT		; (CNT) = Length+3
	STA	CKSUM

	JSR	HEXIN
	STA	DMPPT+1		; Address H
	CLC
	ADC	CKSUM
	STA	CKSUM
	
	JSR	HEXIN
	STA	DMPPT		; Address L
	CLC
	ADC	CKSUM
	STA	CKSUM

	;; Add offset
	LDA	DMPPT
	CLC
	ADC	PT1
	STA	DMPPT
	LDA	DMPPT+1
	ADC	PT1+1
	STA	DMPPT+1
	LDY	#0

	DEC	CNT
	DEC	CNT
	DEC	CNT
	BEQ	LHS3
LHS1
	JSR	HEXIN
	PHA
	CLC
	ADC	CKSUM
	STA	CKSUM		; Checksum

	LDA	RECTYP
	CMP	#'1'
	BNE	LHS2

	PLA
	STA	(DMPPT),Y
	INY
	PHA			; Dummy, better than JMP to skip next PLA
LHS2
	PLA
	DEC	CNT
	BNE	LHS1
LHS3
	JSR	HEXIN
	CLC
	ADC	CKSUM
	CMP	#$FF
	BNE	LHSE		; Checksum error

	LDA	RECTYP
	CMP	#'9'
	BEQ	LHSR
	JMP	LH3
LHSE
	LDA	#$FF&SHEMSG
	STA	PT0
	LDA	#SHEMSG>>8
	STA	PT0+1
	JSR	STROUT
LHSR	
	JMP	WSTART

;;;
;;; Register
;;;
REG
	INX
	JSR	SKIPSP
	JSR	UPPER
	CMP	#0
	BNE	RG0
	JSR	RDUMP
	JMP	WSTART
RG0
	LDY	#$FF&RNTAB
	STY	PT1
	LDY	#RNTAB>>8
	STY	PT1+1
	LDY	#0
RG1
	CMP	(PT1),Y
	BEQ	RG2
	INY
	PHA
	LDA	(PT1),Y
	BEQ	RGE
	PLA
	INY
	INY
	INY
	INY
	INY
	JMP	RG1
RGE
	PLA
	JMP	ERR
RG2
	INY
	LDA	(PT1),Y
	CMP	#$80
	BNE	RG3
	;; Next table
	INY
	LDA	(PT1),Y
	STA	CNT		; Temporary
	INY
	LDA	(PT1),Y
	STA	PT1+1
	LDA	CNT
	STA	PT1
	LDY	#0
	INX
	LDA	INBUF,X
	JSR	UPPER
	JMP	RG1
RG3
	CMP	#0
	BEQ	RGE0

	INY			; +2
	LDA	(PT1),Y
	TAX
	INY

	INY			; +4
	LDA	(PT1),Y
	STA	PT0
	INY
	LDA	(PT1),Y
	STA	PT0+1
	STY	CNT		; Save Y (STROUT destroys Y)
	JSR	STROUT
	LDA	#'='
	JSR	CONOUT
	LDY	CNT		; Restore Y
	DEY
	DEY
	DEY
	DEY
	LDA	(PT1),Y
	STA	REGSIZ
	CMP	#1
	BNE	RG4
	;; 8 bit register
	LDA	0,X
	JSR	HEXOUT2
	JMP	RG5
RG4
	;; 16 bit register
	LDA	1,X
	JSR	HEXOUT2
	LDA	0,X
	JSR	HEXOUT2
RG5
	LDA	#' '
	JSR	CONOUT
	STX	CKSUM		; Save X (GETLIN destroys X)
	JSR	GETLIN
	LDX	#0
	JSR	RDHEX
	LDA	CNT
	BEQ	RGR
	LDX	CKSUM		; Restore X
	LDA	REGSIZ
	CMP	#1
	BNE	RG6
	;; 8 bit register
	LDA	PT1
;	STA	,X
	STA	0,X
	JMP	RG7
RG6
	;; 16 bit address
	LDA	PT1
;	STA	,X		; (L)
	STA	0,X		; (L)
	LDA	PT1+1
	STA	1,X		; (H)
RG7	
RGR	
	JMP	WSTART
	
RGE0	
	JMP	ERR
	
RDUMP
	LDA	#$FF&RDSA	; A
	STA	PT0
	LDA	#RDSA>>8
	STA	PT0+1
	JSR	STROUT
	LDA	REGA
	JSR	HEXOUT2

	LDA	#$FF&RDSX	; X
	STA	PT0
	LDA	#RDSX>>8
	STA	PT0+1
	JSR	STROUT
	LDA	REGX
	JSR	HEXOUT2

	LDA	#$FF&RDSY	; Y
	STA	PT0
	LDA	#RDSY>>8
	STA	PT0+1
	JSR	STROUT
	LDA	REGY
	JSR	HEXOUT2

	LDA	#$FF&RDSSP	; SP
	STA	PT0
	LDA	#RDSSP>>8
	STA	PT0+1
	JSR	STROUT
	LDA	REGSP
	JSR	HEXOUT2

	LDA	#$FF&RDSPC	; PC
	STA	PT0
	LDA	#RDSPC>>8
	STA	PT0+1
	JSR	STROUT
	LDA	REGPC+1		; PC(H)
	JSR	HEXOUT2
	LDA	REGPC		; PC(L)
	JSR	HEXOUT2

	LDA	#$FF&RDSPSR	; PSR
	STA	PT0
	LDA	#RDSPSR>>8
	STA	PT0+1
	JSR	STROUT
	LDA	REGPSR
	JSR	HEXOUT2

	JMP	CRLF

;;;
;;; Other support routines
;;;

STROUT
	LDY	#0
STRO0
	LDA	(PT0),Y
	BEQ	STROE
	JSR	CONOUT
	INY
	JMP	STRO0
STROE
	RTS

HEXOUT2
	PHA
	LSR	A
	LSR	A
	LSR	A
	LSR	A
	JSR	HEXOUT1
	PLA
HEXOUT1
	AND	#$0F
	CLC
	ADC	#'0'
	CMP	#'9'+1
	BCC	HEXOUTE
	CLC
	ADC	#'A'-'9'-1
HEXOUTE
	JMP	CONOUT

HEXIN
	LDA	#0
	JSR	HI0
	ASL
	ASL
	ASL
	ASL
HI0
	STA	HITMP
	JSR	CONIN
	JSR	UPPER
	CMP	#'0'
	BCC	HIR
	CMP	#'9'+1
	BCC	HI1
	CMP	#'A'
	BCC	HIR
	CMP	#'F'+1
	BCS	HIR
	SEC
	SBC	#'A'-'9'-1
HI1
	SEC
	SBC	#'0'
	CLC
	ADC	HITMP
HIR
	RTS
	
CRLF
	LDA	#CR
	JSR	CONOUT
	LDA	#LF
	JMP	CONOUT

GETLIN
	LDX	#0
GL0
	JSR	CONIN
	CMP	#CR
	BEQ	GLE
	CMP	#LF
	BEQ	GLE
	CMP	#BS
	BEQ	GLB
	CMP	#DEL
	BEQ	GLB
	CMP	#' '
	BCC	GL0
	CMP	#$80
	BCS	GL0
	CPX	#BUFLEN-1
	BCS	GL0		; Too long
	STA	INBUF,X
	INX
	JSR	CONOUT
	JMP	GL0
GLB
	CPX	#0
	BEQ	GL0
	DEX
	LDA	#BS
	JSR	CONOUT
	LDA	#' '
	JSR	CONOUT
	LDA	#BS
	JSR	CONOUT
	JMP	GL0
GLE
	JSR	CRLF
	LDA	#0
	STA	INBUF,X
	RTS

SKIPSP
	LDA	INBUF,X
	CMP	#' '
	BNE	SSE
	INX
	JMP	SKIPSP
SSE
	RTS

UPPER
	CMP	#'a'
	BCC	UPE
	CMP	#'z'+1
	BCS	UPE
	ADC	#'A'-'a'
UPE
	RTS

RDHEX
	LDA	#0
	STA	PT1
	STA	PT1+1
	STA	CNT
RH0
	LDA	INBUF,X
	JSR	UPPER
	CMP	#'0'
	BCC	RHE
	CMP	#'9'+1
	BCC	RH1
	CMP	#'A'
	BCC	RHE
	CMP	#'F'+1
	BCS	RHE
	SEC
	SBC	#'A'-'9'-1
RH1
	SEC
	SBC	#'0'
	ASL	PT1
	ROL	PT1+1
	ASL	PT1
	ROL	PT1+1
	ASL	PT1
	ROL	PT1+1
	ASL	PT1
	ROL	PT1+1
	CLC
	ADC	PT1
	STA	PT1
	INC	CNT
	INX
	JMP	RH0
RHE
	RTS

;;;
;;; Interrupt handler
;;;
	;; Interrupt / Break
IRQBRK
	PHA
	PHP
	PLA			; A <= PSR
	AND	#$10		; Check B flag
	BEQ	IBIR
	CLD
	
	PLA			; A
	STA	REGA
	TXA			; X
	STA	REGX
	TYA			; Y
	STA	REGY
	PLA			; PSR (Pushed by BRK)
	STA	REGPSR
	PLA			; PC(L) (Pushed by BRK)
	SEC
	SBC	#2		; Adjust PC to point BRK instruction
	STA	REGPC
	PLA			; PC(H) (Pushed by BRK)
	SBC	#0
	STA	REGPC+1
	TSX			; SP
	STX	REGSP

	LDA	#$FF&BRKMSG
	STA	PT0
	LDA	#BRKMSG>>8
	STA	PT0+1
	JSR	STROUT
	JSR	RDUMP
	JMP	WSTART

IBIR
	PLA
	RTI
	
OPNMSG
	FCB	CR,LF,"Universal Monitor 6502",CR,LF,$00
PROMPT
	FCB	"] ",$00
IHEMSG
	FCB	"Error ihex",CR,LF,$00

SHEMSG
	FCB	"Error srec",CR,LF,$00

ERRMSG
	FCB	"Error",CR,LF,$00

DSEP0
	FCB	" :",$00
DSEP1
	FCB	" : ",$00
IHEXER
        FCB	":00000001FF",CR,LF,$00
SRECER
        FCB	"S9030000FC",CR,LF,$00

IMR65C	FCB	"W65C02S",CR,LF,$00
IMW816	FCB	"W65C816S(Emulation mode)",CR,LF,$00
	
BRKMSG	FCB	"BRK",CR,LF,$00

RDSA	FCB	"A=",$00
RDSX	FCB	" X=",$00
RDSY	FCB	" Y=",$00
RDSSP	FCB	" SP=01",$00
RDSPC	FCB	" PC=",$00
RDSPSR	FCB	" PSR=",$00

RNTAB
	FCB	'A',1
	FDB	REGA,RNA
	FCB	'X',1
	FDB	REGX,RNX
	FCB	'Y',1
	FDB	REGY,RNY
	FCB	'S',$80
	FDB	RNTABS,0
	FCB	'P',$80
	FDB	RNTABP,0
	
	FCB	$00,0		; End mark
	FDB	0,0

RNTABS
	FCB	'P',1
	FDB	REGSP,RNSP
	
	FCB	$00,0		; End mark
	FDB	0,0

RNTABP
	FCB	'C',2
	FDB	REGPC,RNPC
	FCB	'S',$80
	FDB	RNTABPS,0

	FCB	$00,0		; End mark
	FDB	0,0

RNTABPS
	FCB	'R',1
	FDB	REGPSR,RNPSR

	FCB	$00,0		; End mark
	FDB	0,0
	
RNA	FCB	"A",$00
RNX	FCB	"X",$00
RNY	FCB	"Y",$00
RNSP	FCB	"SP",$00
RNPC	FCB	"PC",$00
RNPSR	FCB	"PSR",$00
	
;;;
;;;	Console Driver
;;;

;CONIN_REQ	EQU	0x01
;CONOUT_REQ	EQU	0x02
;CONST_REQ	EQU	0x03
;  ---- request command to PIC
; UREQ_COM = 1 ; CONIN  : return char in UNI_CHR
;          = 2 ; CONOUT : UNI_CHR = output char
;          = 3 ; CONST  : return status in UNI_CHR
;                       : ( 0: no key, 1 : key exist )
;          = 4 ; STROUT : string address = (PTRSAV, PTRSAV_SEG)
;
;UREQ_COM	rmb	1	; unimon CONIN/CONOUT request command
;UNI_CHR	rmb	1	; charcter (CONIN/CONOUT) or number of strings

INIT
	; clear Reqest Parameter Block
	lda	#0
	sta	UREQ_COM
	sta	CREQ_COM
	sta	bank
	sta	reserve
	RTS

CONIN
	lda	#CONIN_REQ

wup_pic
	sta	UREQ_COM
;	sei			; disable interrupt
	wai			; RDY = 0, wait /IRQ detect
;        nop
;        nop
;        nop
;        nop
;        nop
;        nop
;        nop
;        nop

	lda	UNI_CHR
	RTS

CONST
	lda	#CONST_REQ
	jsr	wup_pic
	AND	#$01
	RTS

CONOUT
	pha
	sta	UNI_CHR		; set char
	lda	#CONOUT_REQ
	jsr	wup_pic
	pla
	rts

	;;
	;; Entry point
	;;

	ORG	ENTRY+0		; Cold start
E_CSTART
	JMP	CSTART

	ORG	ENTRY+8		; Warm start
E_WSTART
	JMP	WSTART

	ORG	ENTRY+16	; Console output
E_CONOUT
	JMP	CONOUT

	ORG	ENTRY+24	; (Console) String output
E_STROUT
	JMP	STROUT

	ORG	ENTRY+32	; Console input
E_CONIN
	JMP	CONIN

	ORG	ENTRY+40	; Console status
E_CONST
	JMP	CONST

	;;
	;; Vector area
	;; 

	ORG	$FFFA

	FDB	$0000		; NMI

	FDB	CSTART		; RESET

	FDB	IRQBRK		; IRQ/BRK

	END
