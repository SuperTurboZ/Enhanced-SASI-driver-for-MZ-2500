;------------------------------------
;SASIë“ÇøçáÇÌÇπ
;in
;	D : STS value
;out
;	CF : 0=OK , 1=NG and reset BUS
wait_sasi:
	ld	e,SASI_STS_MCIBRA
;in
;	E : STS mask
wait_sasi_2:
	ld	b,SASI_DEFUALT_TIMEOUT_H
;in
;	B : timeout count H
wait_sasi_3:
	ld	hl,0		;timeout count L
wait_sasi_l:
	in	a,(IO_SASI_STS)
;	ld	c,a			;save STS
	and	e			;mask
	cp	d			;compare
	ret	z			;match
;timeout count
	dec	hl
	ld	a,h
	or	l
	jr	nz,wait_sasi_l
	djnz	wait_sasi_l
	scf
	ret
