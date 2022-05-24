;------------------------------------
;SASI command output
;in
;out
;	CF : 0=data pahse ready , 1=error
;
sasi_cmd6_out:
;wait busfree
	ld	d,SASI_STS_BFREE
	call	wait_sasi
	ret	c
;selection on
	ld	a,(ix+O_PPT_SASIID)	;(B_SASI_ID)
	or	a
	scf
	ret	z			;invalid id
	SASI_SEL_ON_A	
;STS : BSY
	ld	de,BM_SASI_BSY*0x0101
	call	wait_sasi_2
;selection off
	SASI_SEL_OFF
	ret	c
;STS : CMD_IN (|REQ)
	ld	hl,D_SASI_CMD6
	ld	bc,6*0x100 + IO_SASI_DATA
sasi_cmd_tx_l:
	push	bc
	push	hl
	ld	d,SASI_STS_CMD|BM_SASI_REQ
	call	wait_sasi
	pop	hl
	pop	bc
	ret	c
;tx byte
	outi
	jr	nz,sasi_cmd_tx_l
	or	a
	ret
