;------------------------------------
;reset SASI BUS
;in
;out
;	CF : =1
sasi_reset:
	SASI_RST_ON
	ld	b,0
	djnz	$
	SASI_RST_OFF
	scf
	ret
