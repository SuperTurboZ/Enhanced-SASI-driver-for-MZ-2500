;----------------------------------------------------------
;MZ-2500 EH-SASI : common block
;
;INKEY SVCをフックして、SHIFT+CTRLでヘッドリトラクトを実行する。
;
;READ/WRITE はROMからbuff3へコードをロードして実行
;
;下記の処理はROMからMISCブロックを読み込んで実行
;
;・"INIT"ファンクション処理
;・ヘッドリトラクト(SEEK)
;・エラー発生時の後処理
;
;----------------------------------------------------------

;----------------------------------------------------------
;	.nolist
;	include	"iocs.inc"
;	include	"sasi_param.inc"
;	.list
;----------------------------------------------------------

;----------------------------------------------------------
;COMMON CODE area
	org	SASI_COMMON_CODE_TOP

;----------------------------------------------------------
;HD device descripter
	db	"HD",0,0	;'HD'
	db	0x33		;RND,RW
	db	4-1		;4 drives
	db	63		;max directory
	dw	hd_init		;initialize
	dw	0		;ROPEN  RDINF
	dw	0		;WOPEN  WRFIL
	dw	0x0097		;Map iseg# , unkown (FD=90h,MEM=94h,EMM=95,ROM=96h
;	db	0x90,0		;Map iseg# , unkown (FD=90h,MEM=94h,EMM=95,ROM=96h
	dw	254		;BSD size / block
	dw	hd_read		;input
	dw	hd_write	;output
	dw	hd_func		;zffunc
	dw	hd_ctrl		;control
;----------------------------------------------------------
;+19 : parittion table 0x10 x 4
D_PARTITION_TABLE:
;HD1 for partition table
	PARTITION_DATA	0, 0,0,0x000000, 0x000000,33
;HD2
	PARTITION_DATA	0, 0,0,0x000000, 0x000000,0
;	PARTITION_DATA	0, 0,0,MZ1E30_SAFE, MZ1E30_DRV1_OFFSET,MZ1E30_DRV_SIZE
;HD3
	PARTITION_DATA	0, 0,0,0x000000, 0x000000,0
;	PARTITION_DATA	0, 0,1,MZ1E30_SAFE, MZ1E30_DRV0_OFFSET,MZ1E30_DRV_SIZE
;HD4
	PARTITION_DATA	0, 0,0,0x000000, 0x000000,0
;	PARTITION_DATA	0, 0,1,MZ1E30_SAFE, MZ1E30_DRV1_OFFSET,MZ1E30_DRV_SIZE
;+59 : adittional initalize command

;----------------------------------------------------------
;KEYBOARD HOOK (SHIFT+ESC retract)
;----------------------------------------------------------
SASI_COMMON_INKEY_HOOK:
;----------------------------------------------------------
;hd_inkey_hook:
	call	$			;call SVC.INKEY
;check SHIFT+ESC
	ret	z			;KEY OFF ?
	cp	0x1B			;ESC ?
	ret	nz
	bit	2,c			;SHIFT ?
	jr	nz,kbd_retract
	or	b			;zf=0
	ret
;SHIFT+ESC : KEYBOARD SHORTCUT RETRACT
kbd_retract:
	call	pushra			;autosave af,bc,de,hl,ix
;----------------------------------------------------------
;retract all drive (seek safe area)
retract_all:
	ld	a,0x80		;all drive
;----------------------------------------------------------
;retract drive (seek safe area)
;in
;	A : drive bumber / 0x80 = ALL
jp_retract:
	ld	de,ovl_retract_cmd6
	push	de		;return poiunt
ret_retract:
	exx
	ld	h,ROM_LBA_RETRACT
	jr	sasi_load_module

;----------------------------------------------------------
;INIT "HDx:"
hd_init:
	ld	de,ovl_misc_init
	jr	jp_misc_de

;----------------------------------------------------------
;output
;in
;	HL : address
;	DE : size
;	BC : block start
;	(zch): drive
;out
;	CF : 0=ok,1=error
;	A  : error number(case CF=1)
hd_write:
	exx
	ld	hl,ROM_LBA_DATAOUT*0x100+0x0A	;OUT overlay, WRITE(6) command
	jr	sasi_rw_join

;----------------------------------------------------------
;input
;in
;	HL : transfer address
;	DE : size (bytes)
;	BC : block start
;	(zch): drive
;out
;	CF : 0=ok,1=error
;	A  : error number(case CF=1)
;note
;	P-CP/M call with A=0xFF
hd_read:
	exx
	ld	hl,ROM_LBA_DATAIN*0x100+0x08	;IN overlay , READ(6) command
sasi_rw_join:
	ld	(B_SASI_CMD6_CMD),hl		;set SASI command
	ld	h,ROM_LBA_RW_CMD
	call	sasi_load_module
	jp	ovl_cmdrw_cmd6			;ovl_cmd_rw->ovl_rx/ovl_tx

;----------------------------------------------------------
;motor check
hd_ctrl:
hd_noerr:
	xor	a
	ret

;----------------------------------------------------------
;re-initialzie after busreset
;hd_reconfig:
;return if write access
;read initsector
;	ret

;----------------------------------------------------------
;RECOARD over handler
recoard_too_big:
	inc	bc
	ld	a,c
	or	b
	jr	nz,err_capaciry_over
;recoard==0xffff
;----------------------------------------------------------
;goto partation read/write
;in
;	IX : partition data pointer
	ld	de,ovl_misc_partition_rw
	jr	jp_misc_de

;----------------------------------------------------------
;error handling
err_capaciry_over:
;
err_init_param:
;	ld	a,50	;not ready error
	ld	a,3	;data error
	db	0x21	;SKIP2_HL
err_sasi_access:
	ld	a,41	;HW error
	db	0x21	;SKIP2_HL
hd_func:
err_partition_sig:
	ld	a,59	;can't execute
	scf		;set ERROR flag
err_a:
	ld	de,ovl_misc_error_a	;reset BUS & return
;----------------------------------------------------------
;jump address DE in MISC module
jp_misc_de:
	push	de			;jp address
	jr	sasi_load_misc_module
;----------------------------------------------------------
;load overlay module MISC 
sasi_load_misc_module:
	exx
	ld	h,ROM_LBA_MISC
;	exx
;----------------------------------------------------------
;load overlay module
;in
;	H : sector number
;out
sasi_load_module:
;	exx
	ld	bc,0x00a8		;AddrH=0 , port ROM.A
	out	(c),h			;ROM.AH=0,ROM.AM=Hreg.
	inc	c			;port ROM.D
	ld	h,high buff3 
	in	l,(c)			;ROMBLOCK[+00]: dst.addr.l
	dec	b
	in	b,(c)			;ROMBLOCK[+FF]: src.addr.l
	indr				;copy ROMBLOCK[n..+01] to buff3
	exx
	ret

;----------------------------------------------------------
;get partation pointer
;in
;	A  : drive number
;out
;	IX : partition data pointer
get_partition_ix:
	add	a,a
	add	a,a
	add	a,a
	add	a,a			;x16
	add	low	D_PARTITION_TABLE
	ld	ixl,a
	ld	ixh,high D_PARTITION_TABLE
	ret

;----------------------------------------------------------
;SASI driver
;	include	"sasi/sasi_cmd6out.asm"
	include	"sasi/sasi_wait.asm"

;----------------------------------------------------------
 if $>=(COMMON_PARAMETER)
	error	"common area memory over"
 endif
