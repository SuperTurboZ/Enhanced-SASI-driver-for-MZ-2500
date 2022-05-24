;------------------------------------
;SASI CLOSE BUS (after DATA phase)
sasi_close:
;STS_IN
	ld	d, SASI_STS_STSIN|BM_SASI_REQ
	call	wait_sasi
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
