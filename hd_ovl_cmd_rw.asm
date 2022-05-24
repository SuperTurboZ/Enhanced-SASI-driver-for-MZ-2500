;----------------------------------------------------------
;MZ-2500 EH-SASI : parameter & READ/WRITE command
;----------------------------------------------------------

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
;SASI COMMAND READ/WRITE
;in
;	BC    : start recoard
;	DE    : transfer bytes
;	HL    : data pointer
;	(zch) : drier number
;	(B_SASI_CMD6_CMD) : COMMAND & data phase bank
ovl_cmd_rw:
;get arg before save reg
	exx
	ld	hl,(B_SASI_CMD6_CMD)	;next module bank
	exx
;save reg
	call	pushr			;autosave bc,de,hl,ix
;select partition by drive
	ld	a,(zch)
	call	get_partition_ix
;save memory address
	ld	(W_SASI_MEM_ADDR),hl
;zero length check
	ld	a,d
	or	e
	ret	z
;adjust block size
	dec	de
	inc	d			;d += (e!=0)
	ld	e,0			;sector align
	ld	(W_SASI_DATA_SIZE),de
;----------------------------------------------------------
;re-initialize after BUS RESEt
;	ld	a,(ix+O_PPT_INITIALIZED)
;	or	a
;	call	nz,hd_reconfig
;----------------------------------------------------------
;LAD offset
	ld	l,(ix+O_PPT_TOP_LAD0)
	ld	h,(ix+O_PPT_TOP_LAD1)
	ld	a,(ix+O_PPT_TOP_LAD2)
	add	hl,bc
	adc	a,(ix+O_PPT_TOP_LUN)
;set LAD
	ld	(B_SASI_CMD6_LAD0),hl		;LAD0
	ld	l,a				;LUN,LBA2
	ld	(B_SASI_CMD6_LUN_LAD2),hl	;LUN,LBA2 : LBA1
;set NOB , CTRL
	ld	l,d				;L = NOB
	ld	h,(ix+O_PPT_CTRL)		;H = CTRL
	ld	(B_SASI_CMD6_NOB),hl		;CMD[04] NOB , CMD[05] CTRL
;check drive capacity
	ld	h,e				;HL = number of sectors
	add	hl,bc				;HL = end of recoard
	jp	c,recoard_too_big	;over 0x10000
	ld	a,(ix+O_PPT_CAPA_L)
	sub	l
	ld	a,(ix+O_PPT_CAPA_H)
	sbc	a,h
	jp	c,recoard_too_big	;too big then capacity
;sasi command out
	call	sasi_cmd6_out
	jp	c,err_sasi_access
;continue IN / OUT overlay module
;	call	sasi_load_module
;	jp	rwmap
	ld	hl,rwmap
	push	hl
	exx
	jp	sasi_load_module

;----------------------------------------------------------
;SASI driver
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
