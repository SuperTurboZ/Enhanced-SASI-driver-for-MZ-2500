;----------------------------------------------------------
;MZ-2500 enhanced SASI : driver parameter
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
;----------------------------------------------------------
;entry from RWMAP
;in
;	IX : partiton data
	ei
 if ENABLE_CPLFLG
	ld	a,(hd_device_descripter)
	cp	'F'		;FD emulation ?
	jr	nz,not_cpl
	ld	a,(cplflg)
	rrca
	jr	nc,not_cpl
	ld	a,0x2f		;CPL
	ld	(sasi_din_cpl),a
not_cpl:
 endif
;parameter load & check
	ld	de,(W_SASI_DATA_SIZE)
	ld	hl,(W_SASI_MEM_ADDR)
	ld	a,d
	or	e
	call	nz,sasi_din		;DATA phase
	call	nc,sasi_close		;STS,MSG phase
	jr	c,sasi_din_err
;check status byte
	ld	a,(B_SASI_STS)		;LUN[2:0],Spare[2:0],Error,ParityError
	and	0x03			;------,Error,ParityError
	ret	z
sasi_din_err:
	jp	err_sasi_access

;----------------------------------------------------------
;data in phase
;in
; DE : transfer bytes
; HL : memory pointer
sasi_din:
	ld	b,e				;Cnt.L
	dec	de				;16bit to 8bit adjust
	inc	d		
	ld	a,d				;Cnt.h
	exx
	ld	b,a				;B' = Cnt.h
	exx
	ld	c,IO_SASI_DATA			;I/O
	ld	de,0x100*(SASI_STS_DIN|BM_SASI_REQ) | SASI_STS_MCIBRA
;preset timeout counter
	exx
;1st long timeout
;	ld	de,SASI_SEEK_TIMEOUT_HM
;	ld	c,SASI_SEEK_TIMEOUT_L
;	ld	d,SASI_STS_DIN
;	call	wait
sasi_din_hcnt_l:
	ld	de,SASI_DATA_TIMEOUT_HM
	ld	c,SASI_DATA_TIMEOUT_L
sasi_din_tcnt_l:
	exx
sasi_din_lcnt_l:
	in	a,(IO_SASI_STS)
	and	e
	xor	d
	jr	nz,sasi_din_nrdy
;transfer
 if ENABLE_CPLFLG
	in	a,(c)
sasi_din_cpl:
	nop
	ld	(hl),a
	inc	hl
	djnz	sasi_din_lcnt_l
 else
	ini
	jp	nz,sasi_din_lcnt_l
 endif
	exx
	djnz	sasi_din_hcnt_l
	exx
sasi_din_interrupt:
	ld	(W_SASI_END_ADDR),hl	;save end address
	xor	a
	ret
;----------------------------------------------------------
;data phase , not ready
sasi_din_nrdy:
	and	SASI_STS_MCIB			;only phase
	xor	SASI_STS_DIN^SASI_STS_STSIN	;ZF = STATUS phase
	jr	z,sasi_din_interrupt
;
	exx
	dec	c
	jr	nz,sasi_din_tcnt_l
	dec	de
	ld	a,e
	or	d
	jr	nz,sasi_din_tcnt_l
	exx
	scf					;timeout
	ret
	
;----------------------------------------------------------
	include	"sasi/sasi_close.asm"
;	include	"sasi/sasi_wait.asm"
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
;driver common block (reference)
	.nolist
	include	"hd_ovl_misc_dummy.asm"
	include	"hd_common.asm"
	.list
;----------------------------------------------------------

