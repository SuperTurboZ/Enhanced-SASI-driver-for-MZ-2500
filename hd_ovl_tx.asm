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
	ld	(sasi_dout_cpl),a
not_cpl:
 endif
;parameter
	ld	de,(W_SASI_DATA_SIZE)
	ld	hl,(W_SASI_MEM_ADDR)
	ld	a,d
	or	e
	call	nz,sasi_dout	;DATA phase
	call	nc,sasi_close	;STS,MSG phase
	jr	c,sasi_dout_err
	ld	a,(B_SASI_STS)		;LUN[2:0],Spare[2:0],Error,ParityError
	and	0x03			;------,Error,ParityError
	jr	nz,sasi_dout_err
 if 0
	ld	hl,(W_SASI_END_ADDR)
	ld	hl,(W_SASI_MEM_ADDR)
	or	a
	sbc	hl,de
	ld	de,(W_SASI_DATA_SIZE)
	scf
	sbc	hl,de
	jp	nz,err_write_size
 endif
 if 0
	ld	a,(vrffl)
	or	a
	ret	z
;goto verify entry
	ld	a,0xc0			;CTRL = no verify , no error collect
	ld	(B_SASI_CTRL),a
;continue read for verify
	ld	hl,ovl_cmd_vfy
	push	hl
	exx
	ld	h,
	exx
	ld	hl,ROM_LBA_DATAIN*0x100+0x08	;IN overlay , READ(6) command
	exx
	
	jp	sasi_load_module
;	set CTRL
;	goto comamnd
 endif
	or	a		;no error
	ret
;-------------------
;error
sasi_dout_err:
	jp	err_sasi_access

;----------------------------------------------------------
;data out phase
;in
; DE : transfer bytes
; HL : memory pointer
sasi_dout:
	ld	b,e				;Cnt.L
	dec	de				;16bit to 8bit adjust
	inc	d		
	ld	a,d				;Cnt.h
	exx
	ld	b,a				;B' = Cnt.h
	exx
	ld	c,IO_SASI_DATA			;I/O
	ld	de,0x100*(SASI_STS_DOUT|BM_SASI_REQ) | SASI_STS_MCIBRA
;preset timeout counter
	exx
;1st long timeout
;	ld	de,SASI_SEEK_TIMEOUT_HM
;	ld	c,SASI_SEEK_TIMEOUT_L
;	jr	sasi_dout_tcnt_l
sasi_dout_hcnt_l:
;2nd short timeout
	ld	de,SASI_DATA_TIMEOUT_HM
	ld	c,SASI_DATA_TIMEOUT_L
sasi_dout_tcnt_l:
	exx
sasi_dout_lcnt_l:
	in	a,(IO_SASI_STS)
	and	e
	xor	d
	jr	nz,sasi_dout_nrdy
;transfer
if ENABLE_CPLFLG
	ld	a,(hl)
sasi_dout_cpl:
	nop
	out	(c),a
	inc	hl
	djnz	sasi_dout_lcnt_l
 else
	outi
	jp	nz,sasi_dout_lcnt_l
 endif
	exx
	djnz	sasi_dout_hcnt_l
	exx
sasi_dout_interrupt:
	ld	(W_SASI_END_ADDR),hl	;save end address
	xor	a
	ret
;----------------------------------------------------------
;data phase , not ready
sasi_dout_nrdy:
	and	SASI_STS_MCIB			;only phase
	xor	SASI_STS_DOUT^SASI_STS_STSIN	;ZF = STATUS phase
	jr	z,sasi_dout_interrupt
;
	exx
	dec	c
	jr	nz,sasi_dout_tcnt_l
	dec	de
	ld	a,e
	or	d
	jr	nz,sasi_dout_tcnt_l
	exx
	scf					;timeout
	ret

;----------------------------------------------------------
	include	"sasi/sasi_close.asm"
;	include	"sasi/sasi_wait.asm"
;----------------------------------------------------------
OVL_END:
if $>=SASI_PARAMETER
	error	"transfer area memory over"
 endif
;----------------------------------------------------------
;+FF:BLOCK parameter : load source address.L
	org	buff3+255-1
	db	OVL_END-buff3	;load  source address

	.nolist
;----------------------------------------------------------
;driver common block (reference)
	.nolist
	include	"hd_ovl_misc_dummy.asm"
	include	"hd_common.asm"
	.list
;----------------------------------------------------------
	.list
