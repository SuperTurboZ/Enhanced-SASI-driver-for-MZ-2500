hex2asc4:
	push	hl
	ld	a,h
	call	hex2asc2
	pop	hl
	ld	a,l
hex2asc2:
	push	af
	rrca
	rrca
	rrca
	rrca
	call	hex2asc
	pop	af
hex2asc:
	and	0fh
	add	a,'0'
	cp	'9'+1
	jr	c,$+4
	add	a,'A'-'0'-10
	ld	(de),a
	inc	de
	ret
	
