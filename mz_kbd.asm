;----------------------------------------------------------
;MZ-2500 KEYCOARD HANDLER
;----------------------------------------------------------

 if 0
;----------------------------------------------------------
;direct input
;C : -,-,-,CTRL,KANA,SHIFT,LOCK,GRAPH
;A : ascii_code
inkey:
;C : -,-,-,CTRL,KANA,SHIFT,LOCK,GRAPH
	ld	a,0x0B
	call	kbd_getmatrix
	ld	c,a
;
	ld	a,0x08
	call	kbd_getmatrix
;strobe 08 : 4,3,2,1 direct scan
	ld	b,a
	ld	a,'1'
	bit	1,b
	ret	nz
	inc	a
	bit	2,b
	ret	nz
	inc	a
	bit	3,b
	ret	nz
	inc	a
	bit	4,b
	ret	nz
;INKEY mode
	push	bc
	xor	a
	rst	18h
	db	SVC_INKEY
	pop	bc
	ret	nz
	xor	a
	ret
 endif
;
kbd_getmatrix:
	di
	push	bc
	ld	c,0xE8
	in	b,(c)
	push	bc
	ld	c,a
	ld	a,b
	and	0xE0
	or	c
	out	(0xE8),a
	pop	bc
	in	a,(0xEA)
	out	(c),b
	ei
	pop	bc
	cpl
	ret
