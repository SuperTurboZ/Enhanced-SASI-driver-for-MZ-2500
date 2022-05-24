;----------------------------------------------------------
;MZ-2500 EH-SASI : MISC module
;----------------------------------------------------------

DEBUG_INIT	equ	0

;----------------------------------------------------------
;	.nolist
;	include	"iocs.inc"
;	include	"sasi/sasi_reg.inc"
;	include	"sasi_param.inc"
;	.list
;----------------------------------------------------------
	org	buff3-1
;----------------------------------------------------------
;+00:BLOCK parameter : load distination address.L
	db	OVL_END-1

;----------------------------------------------------------
;PARTITION FORMAT signature
;パーティションに更新がない限り、更新は行わない
;hd_partition.asmと同時に変更する
D_PARTITON_SIG:
;+00..0F : partition sig
	include "partation_version.asm"	;YYYYMMDD
	db	0
;--------------------------------------------
;cause access error (need BUS RESET)
;in
;	A = error number
;ovl_misc_error_a:
 if $!=ovl_misc_error_a
	error	"ovl_misc_sasi_bus_err Address Mismatch"
 endif
	push	af
	call	sasi_reset
;HDD re-configuration
;command $C3
;command $C2 : drive parameter ?
	pop	af
	scf
	ret

;-----------------------------------------------------------
;call RETRACT
;in
;  A : drive number / 0x80=ALL
ovl_misc_retract:
;call reload MISC before return
	ld	hl,sasi_load_misc_module
	push	hl
;
ovl_misc_jp_retract:
;jump after bank load
	ld	hl,ovl_retract_cmd6
	push	hl
;load bank & go
	exx
	ld	h,ROM_LBA_RETRACT
	jp	sasi_load_module

;----------------------------------------------------------
;INIT "HDx:"
;INIT "HDx:"+CHR$(OPTION)
;in
; IX  : partition data
; HL  : parameter point
;(zch): drive number
ovl_misc_init:
	call	pushr			;bc,de,hl,ix
;partition data
	ld	a,(zch)
	call	get_partition_ix
;CTRL
	ld	a,(hl)			;+00
	and	0x03			;-,-,-,-,-,-,NoRetry,NoErCol
	rrca
	rrca
	ld	(ix+O_PPT_CTRL),a
;
	ld	a,(zch)			;drive number
	call	ovl_misc_retract
	or	a				;no error
	ret

;----------------------------------------------------------
;PARTITION read/write from cmd_rw
;----------------------------------------------------------
ovl_misc_partition_rw:
	ld	hl,(W_SASI_MEM_ADDR)
	ld	de,D_PARTITON_SIG
	ld	bc,16
;read/write
	ld	a,(B_SASI_CMD6_CMD)
	cp	0x0A				;WRITE(6) ?
	jr	z,ovl_partition_write
	cp	0x08				;READ(6) ?
	jp	nz,err_capaciry_over
;read signature
	ex	de,hl
	ldir
;read partiton table
	ld	hl,D_PARTITION_TABLE
	call ovl_partition_transfer
;fill DUP DATA
	ld	l,e
	ld	h,d
	dec	hl
	ld	bc,0x100 -D_PARTITON_SIG -PARTITION_DATA_SIZE*4
	jr	ovl_partition_ldir_ret

;--------------------------------------
ovl_partition_write:
;comapre signature
	ld	b,c
ovl_partition_sigchk_l:
	ld	a,(de)
	cp	(hl)
	jp	nz,err_partition_sig
	inc	hl
	inc	de
	djnz	ovl_partition_sigchk_l
;store ALL partition data
	ld	de,D_PARTITION_TABLE
ovl_partition_transfer:
	ld	bc,PARTITION_DATA_SIZE*4
ovl_partition_ldir_ret:
	ldir
;store initialize command
	or	a
	ret

;----------------------------------------------------------
 if DEBUG_INIT
msg_init:
	db	"{ctrl="
b_option:
	db	"0}",0
 endif	

;----------------------------------------------------------
;SASI driver
	include	"sasi/sasi_reset.asm"

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
