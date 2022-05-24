;----------------------------------------------------------
;MZ-2500 EH-SASI : IPL-PROGRAM & installer
;Copyright(c) 2022 @SuperturboZ
;
;note
;SASIドライバーIPLインストーラー
;
;動作手順
;
;・IPLから"ROM:"に格納された本プログラムが起動
;
;・SASIドライバの常駐部をcommom RAM buff6にコピー
;・HDのequipment table（デバイスディスクリプタ）を登録
;・SVC INKEY をSASIドライバへフック
;
;・ROMアクセスをフックするドライバを登録
;・IPLのROMブートの手前部分を差し戻す
;
;・IPLのIPLレコードリードアクセスのフックで捕まえる
;・ROMアクセスをフックするドライバを削除して元に戻す
;・カレントデバイスをROMから起動デバイスに差し替え
;・起動デバイスに対してリード処理を行い、エラーを無視して戻す
;
;・IPLは差し替えデバイスをROMと思い込んで起動処理を続ける
;
;----------------------------------------------------------

;----------------------------------------------------------
;	include	"iocs.inc"
;	include	"sasi_param.inc"
;----------------------------------------------------------

;MENUキーコード
KCODE_MENU1	equ	0x20     ;space
;KCODE_MENU2	equ	0x98	;ALGO

;SPACE KEY 待ち時間
KEY_INPUT_WAIT	equ	10000

;COMMON CODE address
DRIVE_COMMON_SRC	equ	0x8000+(ROM_LBA_COMMON-ROM_LBA_IPL_PROGRAM)*0x100
;PARTITION signature (top of MISC block code)
PARTITION_SIG_SRC	equ	0x8000+(ROM_LBA_MISC-ROM_LBA_IPL_PROGRAM)*0x100 +0x01

;PARTITION recoard buffer
PARTITION_BUF	equ	0xF100

;----------------------------------------------------------
INSTALL_TOP	equ	0xe000
;
	org	INSTALL_TOP
;----------------------------------------------------------
;IPL FCB
	db	0x01			;+00     ; system-type 01=MZ-80B/2000/2500
	db	"IPLPRO"		;+01..06 : IPL signature
	db	"EH-SASI   ",0x0d	;+07..11 : system name
	db	0,0,0,0,0,0		;+12..17 : un-reference
	dw	0x8100			;+18..19 : exec address
	db	0,0,0,0			;+1A..1D : un-reference
	dw	0x0000			;+1E..1F : start recoard no.
	db	0x04,0xff		;+20..2F : load memory block list (0xFF=end)
	db	0,0,0,0,0,0
	db	0,0,0,0,0,0,0,0		
	db	0x00,0x01,0x34,0x35,0x04,0x05,0x33,0x0F ;+30..37 : execute memory map
;	db	0x00,0x01,0x34,0x35,0x2F,0x05,0x33,0x0F	 ;(IPL loading)
	db	0,0,0,0,0,0,0,0	;+38..3F : un-reference
;----------------------------------------------------------
;+040 : driver version
D_DRIVER_SIG:
	db	"EHSASI "		;+80 Dirver Name + Version Code
D_DRIVER_VER:
	include	"version.asm"
	db	0
;+050 : Copyright
	org	INSTALL_TOP+0x50
D_COPYRIGHT:
	db	"Copyright(c) 2022 @Superturbo"
	db	0
	org	INSTALL_TOP+0x80
;+080 : Licence
D_LICENCE:
	db	"MZ-2500 EH-SASI is released under the Creative Commons,BY SA 4.0"
	db	0
;	dw	0,0,0,0,0,0,0,0
;	dw	0,0,0,0,0,0,0,0
;	dw	0,0,0,0,0,0,0,0
;	dw	0,0,0,0,0,0,0,0
;	dw	0,0,0,0,0,0,0,0
;	dw	0,0,0,0,0,0,0,0
;	dw	0,0,0,0,0,0,0,0

;----------------------------------------------------------
	org	0xE100
;exec on memory 0F
	ld	hl,0x8000
	ld	de,0xe000
	ld	bc,0x0900	;installer + COMMON
	ldir
	jp	bios_entry

;----------------------------------------------------------
;same as entry enviroment
bios_entry:
	ei
;get IOCS version
	ld	a,4
	out	(0xb4),a
	ld	bc,0x37b5
	in	e,(c)		;save
	out	(c),b		;IPL #3
	ld	a,(0x9fff)	;ROMV version
	ld	(b_iocs_ver),a
	out	(c),e		;restore
	ld	de,msg_romver
	call	hex2asc2
;--------------------------------------
;kbd escape mode check
kbd_fd_only_check:
	ld	a,0x0B		;-,-,-,CTRL,KANA,SHIFT,LOCK,GRAPH
	call	kbd_getmatrix	;direct KEY IN
	bit	2,a		;SHIFT ON ?
	jp	nz,fd_bypass_boot
;--------------------------------------
normal_boot:
;boot message
	ld	de,msg_title
	rst	18h
	db	SVC_CRTMS
;copyright
	ld	de,D_COPYRIGHT
	rst	18h
	db	SVC_CRTMS
;
	rst	18h
	db	SVC_CR1
	rst	18h
	db	SVC_CR1
;
	ld	de,D_LICENCE
	rst	18h
	db	SVC_CRTMS
;
	ld	de,msg_boot2
	rst	18h
	db	SVC_CRTMS

;--------------------------------------
;IOCS check
	call	iocs_check
;
	ld	de,msg_search_points
	rst	18h
	db	SVC_CRTMS

;--------------------------------------
;install ROM access hook driver
	ld	hl,romhook_dev
	ld	(DEV_PTR_ROM),hl

;--------------------------------------
;insatall HD driver common block
	ld	hl,DRIVE_COMMON_SRC
	ld	de,buff6		;install
	ld	bc,buff6_size
	ldir
;--------------------------------------
;check partition table
	call	partition_precheck
;--------------------------------------
;kbd menu
	ld	de,msg_press_menukey
	rst	18h
	db	SVC_CRTMS
;KBD check & set boot mode
	call	keyboard_check
;CR
	rst	18h
	db	SVC_CR1
;--------------------------------------

;--------------------------------------
;insatall HD driver common block
;	ld	hl,0x8000+(ROM_LBA_COMMON-ROM_LBA_IPL_PROGRAM)*0x100	;COMMON CODE
;	ld	de,buff6		;install
;	ld	bc,buff6_size
;	ldir
;regist HD device description
	call	register_hd_device
;hook INKEY function 
	ld	hl,(0x0300 +SVC_INKEY*3)	;0x0F INKEY.ENTRY
	ld	(SASI_COMMON_INKEY_HOOK+1),hl	;call INKEY_ORG
	ld	hl,SASI_COMMON_INKEY_HOOK
	ld	(0x0300 +SVC_INKEY*3),hl
;--------------------------------------
;load partition table again
	ld	a,1		;show only active
	call	partition_autosetup
;--------------------------------------
;2nd IPL call
exec_ipl:
	di
;free MEMORY block
	ld	a,0x40
	ld	(0x544),a		;MEM 0x04 free
;
	ld	sp,0x2000
	ld	a,4
	out	(0xb4),a
	ld	a,0x2F
	out	(0xb5),a
	ld	hl,(w_fdxdboot_entry)	;XDROM + FD boot again
call_hl:
	jp	(hl)

;----------------------------------------------------------
;exec FD only boot
fd_bypass_boot:
;IOCS check
	call	iocs_check
;install ROM access hook driver
	ld	hl,romhook_dev
	ld	(DEV_PTR_ROM),hl
;FD mode boot
	ld	a,1
	ld	(b_fd_only_boot),a
	ret

;----------------------------------------------------------
;install HD device
register_hd_device:
;emu mode check
	ld	a,(b_fdemu_mode)
	or	a
	jr	nz,register_fdemu_device
;move RS driver to #15 (for P-CP/M)
	ld	hl,(DEV_PTR_RS)		;RS
	ld	(DEV_PTR_15),hl		;last block
;install HD device
	ld	hl,hd_device_descripter
	ld	(DEV_PTR_RS),hl
	ret

;----------------------------------------------------------
;install FD/EMU emulation mode
register_fdemu_device:
;swap HD and emu device
	ld	bc,hd_device_descripter
	ld	hl,(w_emu_device)	;EMU target
	ld	e,(hl)
	ld	(hl),c
	inc	hl
	ld	d,(hl)
	ld	(hl),b	
	ex	de,hl				;HL = EMU device descripter
;	ld	(DEV_PTR_RS),hl		;save EMU device entry
;set emu device name to HD
	ld	e,c
	ld	d,b
	ld	bc,4				;name
	ldir
	ret

;----------------------------------------------------------
iocs_check:
;search IPL re-entry point
	ld	hl,0x7800		;search top
	ld	de,d_ipl_retry_code	;search code
	ld	b,d_ipl_retry_code_size	;search length
	call	search_rom
	jr	c,err_ipl_not_found
	ld	(w_fdxdboot_entry),hl
	ld	de,msg_ipl_reentry
	call	hex2asc4
;save ROM device descriptor
	ld	hl,(DEV_PTR_ROM)	;ROM device
	ld	(w_rom_device_save),hl	;save
	ld	a,(hl)
	cp	'R'			;check compatible
	jr	nz,err_rom_driver
	ld	de,msg_rom_desc
	call	hex2asc4
	ret

;----------------------------------------------------------
;error handle
err_rom_driver:
	ld	de,msg_romderv_not_found
	jr	fatal_err
;
err_ipl_not_found:
	ld	de,msg_ipl_not_found
fatal_err:
	rst	18h
	db	SVC_CRTMS
	jr	$

;----------------------------------------------------------
;search ROM code
search_rom:
	push	bc
	push	de
	push	hl
	call	memcmp_hl_de_b
	pop	hl
	pop	de
	pop	bc
	ret	z	;found
	inc	hl	;next address
	bit	7,h
	jr	z,search_rom
	scf
	ret		;not found

;----------------------------------------------------------
;
memcmp_hl_de_b:
	ld	a,(de)
	cp	(hl)
	ret	nz
	inc	hl
	inc	de
	djnz	memcmp_hl_de_b
	ret

;----------------------------------------------------------
;
keyboard_check:
;cause error
	ld	a,(b_menu_open)
	or	a
	jr	nz,wait_key_and_menu
;
;timeout scan
	ld	hl,KEY_INPUT_WAIT
getkey_wait_l:
	ld	a,(b_menu_open)
	or	a
	jr	nz,option_menu
;key scan
	push	hl
	xor	a
	rst	18h
	db	SVC_INKEY
	pop	hl
	jr	nz,kbd_pressed
;wait
	dec	hl
	ld	a,l
	or	h
	jr	nz,getkey_wait_l
;timeout
	xor	a		;CF=0 timeout done
	ret

;----------------------------------------------------------
;kbd task
;in
;	A,B : keycode
;out
;	CF  : 0=accept command , 1 = not accept
;
kbd_pressed:
;	ld	a,b
	cp	KCODE_MENU1
	jr	z,option_menu
;	cp	KCODE_MENU2
;	jr	z,option_menu
;
kbd_process:
;4,3,2,1
	cp	'1'
	jr	c,kbd_no_num4321
	cp	'4'+1
	jr	nc,kbd_no_num4321
	jr	kbd_4321
kbd_no_num4321:
;F4,F23,F2,F1
	cp	0x81
	jr	c,kbd_no_func
	cp	0x81+10
	jr	c,kbd_f20f1
kbd_no_func:
 if 0
;CTRL
	cp	23					;CTRL+W
	jr	z,kbd_press_ctrl_w
 endif
;alphabet
	or	0x20				;to small
	cp	'f'
	ld	hl,fn_fd1
	ld	de,DEV_PTR_FD		;w_emu_device
	jr	z,set_emulatiom_boot	;FD1 <- HD & boot FD
	cp	'e'
	ld	hl,fn_emm
	ld	de,DEV_PTR_EMM		;w_emu_device
	jr	z,set_emulatiom_boot	;EMM <- HD & boot EMM
	cp	'g'
	jr	z,set_emulatiom_only	;EMM <- HD & boot FD
	scf				;not proccesed
	ret

 if 0
;----------------------------------------------------------
;
kbd_press_ctrl_w:
	call	partition_save_hd
	ld	de,msg_partiton_write_ok
	jr	nc,partiton_write_ok
	ld	de,msg_partiton_write_err
partiton_write_ok:
	rst	18h
	db	SVC_CRTMS
ipl_halt:
	ld	de,msg_halt
	rst	18h
	db	SVC_CRTMS
	jr	$
 endif

;----------------------------------------------------------
;wait menukey key and menu
wait_key_and_menu:
partition_load_err_wait:
	ld	a,0x01
	rst	18h
	db	SVC_INKEY
	cp	KCODE_MENU1
	jr	z,option_menu
;	cp	KCODE_MENU2
;	jr	nz,partition_load_err_wait
;
	jr	option_menu

;----------------------------------------------------------
;Option Menu
option_menu:
	ld	a,1
	ld	(b_menu_open),a
;
	ld	de,msg_option_menu
	rst	18h
	db	SVC_CRTMS
;show all partition
	ld	a,2						;show all
	call	partition_autosetup
;select menu
	ld	de,msg_select
	rst	18h
	db	SVC_CRTMS
;
option_menu_l:
	ld	a,0x01
	rst	18h
	db	SVC_INKEY
	or	a
	jr	z,option_menu_l
;	
	call	kbd_process
	ret	nc
	jr	option_menu_l

;--------------------------------------
;FUNCTION KEY
kbd_f20f1:
	bit	2,c		;+SHIFT?
	jr	nz,kbd_f20f11
;F10..F1
	cp	0x81+4
	jr	c,kbd_f4321		;F1..F4
kbd_f10f5:
	sub	0x81-1	;1..15
	jr	kbd_swap_hd
;
kbd_f20f11:
	cp	0x81+5
	ccf
	ret	c			;F16..F20
;F11..F15
	sub	0x81-11
	jr	kbd_swap_hd
;
kbd_swap_hd:
	ld	h,a
	ld	l,1		;HD1:
	call	partition_swap
	pop	hl
	jp	option_menu

;--------------------------------------
;HD boot
kbd_f4321:
	sub	0x81-'1'	;1,2,3,4
;
kbd_set_hd_mode:
	ld	(fn_hd_n),a		;HD{A-4}:
	or	a			;CF=0 accept
	ret

;--------------------------------------
;FD boot with HD mode
kbd_4321:
;
kbd_set_fd_mode:
	ld	(fn_fd_n),a		;FD{A}:
	ld	hl,fn_fd1
set_boot_device_ok:
	ld	(w_1st_boot_device),hl	;set FD
	or	a			;CF=0 accept
	ret
;--------------------------------------
;emulation mode
; DE : emulation target
; HL : emulation device name
set_emulatiom_only:
	ld	hl,fn_fd1
set_emulatiom_boot:
	ld	a,1
	ld	(b_fdemu_mode),a
	ld	(w_emu_device),de	;emu target
	jr	set_boot_device_ok

;--------------------------------------
;check partition table
partition_precheck:
;read ?
	call	partition_read_hd
	jr	c,partitoin_load_err
;valid ?
	ld	a,0				;no-display
	call	partition_autosetup
	jr	nc,partitoin_table_ok
;invalid recoard
	ld	de,msg_invalid_partition
	rst	18h
	db	SVC_CRTMS
partitoin_load_err:
	ld	a,1
	ld	(b_menu_open),a			;open menu mode
	scf
	ret
;-------------------------
;partitoin table ready
partitoin_table_ok:
	add	a,'0'
	ld	(fn_hd_n),a	;set priority_boot drive
	ret

;--------------------------------------
;
b_iocs_ver:
	db	0
w_fdxdboot_entry:
	dw	0

;IPL re-entry search code
d_ipl_retry_code:
	ld	a,0xff
	ld	(0xf816),a
d_ipl_retry_code_size	equ	$-d_ipl_retry_code

;--------------------------------------
;messanges

msg_title:
	db	0x0d,0x0d
	db	"Enhanced SASI BIOS Ver."
	include "version.asm"	;YYYYMMDD
	db	0x0d,0
msg_boot2:
	db	0x0d,0x0d
	db	"Don't use with MZ-1F23,or real HDD",0x0d,0x0d
;
	db	"IOCS Ver.0"
msg_romver:
	db	"xxH :",0

msg_search_points:
	db	"IPL reentry 0"
msg_ipl_reentry:
	db	"xxxxH",0x0d
	db	"ROM: table 0"
msg_rom_desc:
	db	"xxxxH",13
	db	0
;
msg_press_menukey:
	db	"Press SPACE KEY to open MENU",0x0d
	db	0

msg_option_menu:
	db	0x0c
	db	"Enhanced SASI BIOS menu",0x0d,0x0d,0
;
msg_select:
	db	0x0d
	db	"boot+SHIFT: no HD-BIOS",0x0d
	db	" F1..F4   : Boot from HD1..HD4",0x0d
	db	" F5..F15  : Swap HD1 and Pn",0x0d
	db	"  1.. 4   : Boot from FD1..FD4",0x0d
;	db	"  F    :Emulate FD* with HD* and boot FD1",0x0d
;	db	"  E    :Emulate EMM with HD1 and boot EMM",0x0d
;	db	"  G    :Emulate EMM with HD* and boot FD1",0x0d
;	db	"CTRL+W:Write Partition Table to HD",0x0d
	db	"Select :"
	db	0
;
msg_ipl_not_found:
	db	"Err:IPL re-entry point not found",0
;
msg_romderv_not_found:
	db	"Err:ROM device descriptor not found",0
;
msg_hdboot:
;	db	"Searching the bootable HD",0x0d,0x0d,0
	db	13,13,"Looking for ",0

;partitoin
msg_invalid_partition:
	db	0x0d
	db	"Invalid partition table",0x0d
	db	"Press KEY to load default",0x0d,0

 if 0
msg_partiton_write_ok:
	db	"writed !",0x0d,0

msg_partiton_write_err:
	db	"write error !",0x0d,0
msg_halt:
	db	"HALT:press IPL button to reboot",0x0d
 endif

;--------------------------------------
;ROM device hook descripter
romhook_dev:
	db	"ROM",0		; 'HD',0,0
	db	0x31		;RND,RW
	db	1-1		;1ch
	db	63		;max directory
	dw	rom_ret		;initialize
	dw	0		;read open  (CMT)
	dw	0		;write open (CMT)
	dw	0x9600		;
	dw	254		;BSD block
rom_hook_read_entry:
	dw	hook_romread	;input
	dw	0		;output
	dw	0		;+0x1D : ffunc
	dw	rom_ret		;control
zarea_size	equ	$-romhook_dev

;--------------------------------------


;----------------------------------------------------------------------------
;2nd IPL boot , ROM read entry hook
;in
;	HL : address
;	DE : size
;	BC : block start
hook_romread:
	push	bc
	push	de
	push	hl
;kill 'IPLPRO' signature for read error case
	inc	hl
	ld	(hl),0	;+01 : 'I'
;restore hooked ROM driver entry
	ld	hl,(w_rom_device_save)
	ld	(DEV_PTR_ROM),hl	;ROM device

;FD only bypass mode
	ld	a,(b_fd_only_boot)
	or	a
	jr	nz,hook_romread_fd_only

;set alternate boot device name
	ld	de,(w_1st_boot_device)	;"HD1:" , etc.
;set IPL boot drive number (for SYS LOADER)
	inc	de
	inc	de
	ld	a,(de)		;number in DEVNAME
	dec	de
	dec	de
	sub	'1'
	jr	c,no_drive_number
	cp	10
	jr	c,has_drive_number
no_drive_number:
	xor	a
has_drive_number:
	ld	(lddsk),a			;drive number

;current device to BOOT device
	ld	b,4				;length
	ld	a,1
	rst	18h
	db	SVC_IOSUB
	rst	18h
	db	SVC_CHDIR
;message
 if 1
	ld	de,msg_hdboot
	rst	18h
	db	SVC_CRTMS
	ld	de,(w_1st_boot_device)
	rst	18h
	db	SVC_CRTMS
 endif
	pop	hl
	pop	de
	pop	bc
	xor	a		;drive 0
	call	hd_read_func	;read IPL recoard from HD device
	jr	c,boot_fcb_read_error
;---------------------
;ipf_fcb read OK
hook_romread_next_fd:
	ld	a,0xff		;set fd_mode : do not next bypass ROM if loading error
	ld	(fdxd),a
	xor	a		
	ret

;---------------------
;only FD boot
hook_romread_fd_only:
	pop	hl
	pop	de
	pop	bc
	xor	a
;	ld	(fdxd),a
	ret

;---------------------
boot_fcb_read_error:
	ret	nc					;no error
 if 0
;wait
	ld	b,2
	ld	hl,0
wait_1:
	dec	l
	jr	nz,wait_1
	dec	h
	jr	nz,wait_1
	djnz	wait_1
 endif
rom_ret:
	or	a			;set no error (for contine FD BOOT)
	ret

;--------------------------------------------
;redirect read function entry
hd_read_func:
	push	hl
	ld	hl,(zinp)		;current handler
	ex	(sp),hl
	ret
;--------------------------------------------
;
w_rom_device_save:
	dw	0

b_fd_only_boot:
	db	0

b_fdemu_mode:
	db	0
w_emu_device:
	dw	0
;
b_menu_open:
	db	0
;
w_1st_boot_device:
	dw	fn_hd1
;
fn_hd_n	equ	$+2
fn_hd1:
	db	"HD1:",0
fn_fd_n	equ	$+2
fn_fd1:
	db	"FD1:",0
fn_emm:
	db	"EMM:",0
fn_non:
	db	"XXX:",0

;----------------------------------------------------------
	include	"hd_partition.asm"
	include	"hex2asc.asm"
	include	"mz_kbd.asm"
;----------------------------------------------------------

;----------------------------------------------------------
;end of boot block (3block)
;----------------------------------------------------------
 if $>=(0xE800)
	error	"installer area memory over"
 endif
;----------------------------------------------------------
