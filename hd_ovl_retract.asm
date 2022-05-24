;----------------------------------------------------------
;MZ-2500 enhanced SASI : driver parameter
;----------------------------------------------------------

DEBUG_RETRACT	equ	0

;----------------------------------------------------------
	.nolist
	include	"iocs.inc"
	include	"sasi/sasi_reg.inc"
	include	"sasi_param.inc"
	.list
;----------------------------------------------------------
	org	buff3-1
;----------------------------------------------------------
;+00:BLOCK parameter : load distination address.L
	db	OVL_END-1
	org	buff3
;----------------------------------------------------------
;SASI COMMAND RETRACT (SEEK)
;in
;	A : drive bumber / 0x80 = ALL
ovl_cmd_retract_multi:
	cp	0x80
	jr	c,ovl_cmd_retract_one
;all drive
	ld	a,3
ovl_cmd_retract_l:
	push	af
	call	ovl_cmd_retract_one
	pop	af
	dec	a
	jr	nz,ovl_cmd_retract_l
;	jr	ovl_cmd_retract_one

;----------------------------------------------------------
;SASI COMMAND RETRACT (SEEK)
;in
;	A : drive bumber
ovl_cmd_retract_one:
 if DEBUG_RETRACT
	push	af
	srl	a
	add	a,'0'
	ld	(b_retract_lun),a
	ld	de,msg_retract
	rst	18h
	db	SVC_CRTMS
	pop	af
 endif
;	call	pushr			;no save regs.
	call	get_partition_ix
;set CMD
	ld	a,0x0B	;SEEK(6) command
	ld	(B_SASI_CMD6_CMD),a
;set LAD
	ld	a,(ix+O_PPT_SAFE_LAD2)
	ld	h,(ix+O_PPT_SAFE_LAD1)
	ld	l,(ix+O_PPT_SAFE_LAD0)
	or	(ix+O_PPT_TOP_LUN)
	ld	(B_SASI_CMD6_LUN_LAD2),a
	ld	(B_SASI_CMD6_LAD1),hl
;check no-need retract
	or	l
	or	h					;zf= SAFE_LAD==0
	ret	z					;no-need retract
;set NOB , CTRL
	ld	hl,0x0000
	ld	(B_SASI_CMD6_NOB),hl
;sasi access
	call	sasi_cmd6_out	;CMD phase
	call	nc,sasi_close	;STS,MSG phase
	ret	c					;bus error
;check status byte
	ld	a,(B_SASI_STS)		;LUN[2:0],Spare[2:0],Error,ParityError
	and	0x03			;------,Error,ParityError
	ret	z
	scf
	ret

;------------------------------------
;SASI CLOSE BUS (after DATA phase)
sasi_close:
;STS_IN
;	ld	d, SASI_STS_STSIN|BM_SASI_REQ
;	call	wait_sasi
	ld	de, 256*(SASI_STS_STSIN|BM_SASI_REQ)+SASI_STS_MCIBRA
	ld	b,SASI_SEEK_TIMEOUT_H
	call	wait_sasi_3
	ret	c
	in	a,(IO_SASI_DATA)
	ld	(B_SASI_STS),a
;MSG_IN
	ld	d, SASI_STS_MSGIN|BM_SASI_REQ
	call	wait_sasi
	ret	c
	in	a,(IO_SASI_DATA)
	ld	(B_SASI_MSG),a
	or	a
	ret

;----------------------------------------------------------
 if DEBUG_RETRACT
msg_retract:
	db	"{retract LUN="
b_retract_lun:
	db	"0}",0
 endif
	
;----------------------------------------------------------
;SASI driver
;	include	"sasi/sasi_close.asm"
	include	"sasi/sasi_cmd6out.asm"
;----------------------------------------------------------
OVL_END	equ	$
 if $>=SASI_PARAMETER
	error	"transfer area memory over"
 endif
;----------------------------------------------------------
;+FF:BLOCK parameter : load source address.L
	org	buff3+255-1
	db	OVL_END-buff3	;load  source address
;----------------------------------------------------------

;----------------------------------------------------------
;driver common block (reference)
	.nolist
	include	"hd_ovl_misc_dummy.asm"
	include	"hd_common.asm"
	.list
;----------------------------------------------------------
