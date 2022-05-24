;----------------------------------------------------------
;MZ-2500 enhanced SASI : driver parameter
;
;note
; 1.load from partiotn recoard (ID=0,LUN=0,LAD=0x00_00003)
;   load ok
;   signature ok
;   then load 
; 2.default 4 drive data
;
;----------------------------------------------------------

;----------------------------------------------------------
;read partition recoard from HD
;in
;	A : display info level
;out
;	CF: 0= read OK , 1=read NG
partition_read_hd:
;load partitoin reoard
	call	partition_load_hd
	ret	nc
;read error , ;show message
	ld	de,msg_pert_recocard_cantread
	rst	18h
	db	SVC_CRTMS
;generate zero fill partation
	call	partition_signature_set
	ex	de,hl
	ld	bc,0x0100-0x10
	xor	a
	call	fill_memory
	scf					;error clear
	ret

;----------------------------------------------------------
;partition load from HD
;in
;	A : display info level
;out
;	CF: 0=partiotn recoard found , 1=load default
;	A : priority boot device
partition_autosetup:
;display level
	ld	(B_DISP_LEVEL),a
;
	call	partition_signature_check
	jr	c,partition_default
;
	call	partition_setup
	or	a
	ret
;----------------------------------------------------------
;load error , load default
partition_default:
	call	partition_load_def
	call	partition_setup
	scf
	ret


;----------------------------------------------------------
;partition write to HD
;in
;out
partition_write:
	call	partition_save_hd
	ret

;----------------------------------------------------------
;partition table setup
;in
;	(PARTITION_BUF)     : partiotin table recoard
;out
;	(D_PARTITION_TABLE) : partition table in driver
;	A : priority boot drive

;----------------------------------------------------------
partition_setup:
	ld	de,msg_partition_item
	ld	b,1
	call	puts_levelb
;load partition data
	ld	ix,PARTITION_BUF+0x10
	ld	bc,15*256+0		;max 15 partition
partition_load_l1:
	push	bc
	ld	a,(ix+O_PPT_SASIID)			;validate
	or	a
	jr	z,no_partiton_data
;decode & show partition
	push	ix
	pop	hl
	ld	a,c			;part number
	call	build_partiton_msg	;decode to string
;active partition ?
	ld	a,(ix+O_PPT_ACTIVE)
;default boot device ?	
	bit	7,a		
	jr	z,partition_no_autoboot
	ld	(B_HD_AUTOBOOT),a	;set auto boot dev
partition_no_autoboot:
	and	0x0f			;low 4bit = drive
	dec	a			;orign 1->0
	cp	4
	ld	b,2			;DISP level for inactive part.
	jr	nc,inactive_partiton	;drive >= 4 , sub partition
;active partition (0,1,2,3) : copy to driver partitoin table
;load partition->
	ld	hl,D_PARTITION_TABLE-PARTITION_DATA_SIZE
	ld	bc,PARTITION_DATA_SIZE
	inc	a			;1..4
partition_addr_sel_l:
	add	hl,bc
	dec	a
	jr	nz,partition_addr_sel_l
	ex	de,hl			;de = &D_PARTITION_TABLE[drive]
	push	ix			;
	pop	hl			;hl = &PARTITION_BUF[n]
	xor	a			;CTRL byte
	ld	(de),a			;set O_PPT_CTRL = 0x00
	inc	hl
	inc	de
	dec	bc
	ldir				;copy +01..end
;<-load partition
	ld	b,1			;DISP level for active part.
inactive_partiton:
	ld	de,msg_partition
	call	puts_levelb		;DISP partition info.
no_partiton_data:
	ld	de,PARTITION_DATA_SIZE
	add	ix,de
	pop	bc
	inc	c			;next num
	djnz	partition_load_l1
;
	ld	a,(B_HD_AUTOBOOT)
	and	0x0f			;auto boot device
;
	ret

;----------------------------------------------------------
;partition replace
;in
;	H  : swap drive
;	L  : swap drive
;out
;	A  : mount number data ( bit7..4 = flag),0=not found
;	DE : DE+0x10
;	IX : partition src ptr.
partition_swap:
	ld	ix,PARTITION_BUF+0x10
	ld	b,15			;scan 15 partition
partition_swap_l:
	ld	a,(ix+O_PPT_ACTIVE)
	ld	e,a
	and	0xf0			;flag
	ld	d,a			;flag
	xor	e
	ld	e,a			;drive
;swap check
	ld	a,l
	cp	e
	ld	a,h
	jr	z,hit_swap_drive
	cp	e
	ld	a,l
	jr	nz,nohit_swap_drive
hit_swap_drive:
	or	d			;set flag
	ld	(ix+O_PPT_ACTIVE),a	;dst <- new
nohit_swap_drive:
	ld	de,PARTITION_DATA_SIZE
	add	ix,de
	djnz	partition_swap_l
	ret

;----------------------------------------------------------
puts_levelb:
	ld	a,(B_DISP_LEVEL)
	cp	b
	ret	c
	rst	18h
	db	SVC_CRTMS
	ret

;----------------------------------------------------------
;set HD0 to partiiton reocard area
;in
;out
;	CF : HD initialize error
;	HL : PARTITION_BUF
;	BC : partition recoard address
;	DE : partition buffer size (=0x100)
partition_table_set_hd0:
;set HD0: to RAW access
	ld	hl,D_PARTITION_RAW
	ld	de,D_PARTITION_TABLE
	ld	bc,D_PARTITION_RAW_SIZE
	ldir
;SASI INIT
;	call	sasi_initialize
;SASI REZERO UNIT
;SASI REQUEST SENSE
;set drive "HD0:"
	xor	a			;1st HDD (ID=0,LUN=0)
	ld	(zch),a			;drive (before load partition)
;result
	ld	hl,PARTITION_BUF	;buffer
	ld	bc,PARTITON_RECOARD	;partition recoard
	ld	de,0x0100		;size
	or	a
	ret

;----------------------------------------------------------
;set partiiton signature code
partition_signature_set:
	ld	hl,PARTITION_SIG_SRC
	ld	de,PARTITION_BUF
	ld	bc,0x0010
	ldir
	ret

;----------------------------------------------------------
;check partiiton signature
partition_signature_check;
	ld	hl,PARTITION_SIG_SRC
	ld	de,PARTITION_BUF
	ld	b,16	
partition_file_sig_l:
	ld	a,(de)
	cp	(hl)
	scf			;compare error
	ret	nz
	inc	hl
	inc	de
	djnz	partition_file_sig_l
	xor	a		;compare OK
	ret

;----------------------------------------------------------
;load partiiton reocard
partition_load_hd:
;set HD0: to RAW access
	call	partition_table_set_hd0
	call	nc,hd_read
	ret

;----------------------------------------------------------
;load partiiton reocard
partition_save_hd:
;make signature
	call	partition_signature_set
;set HD0: to RAW access
	call	partition_table_set_hd0
	call	nc,hd_write
	ret

;----------------------------------------------------------
;load default partiton code
partition_load_def:
;load signature
	call	partition_signature_set
;load default partition data
	ld	hl,D_PARTITION_1E30
	ld	bc,D_PARTITION_1E30_SIZE
	ldir
;fill ignore space
	ex	de,hl
	ld	bc,0x0100-0x10-D_PARTITION_1E30_SIZE
	xor	a
	call	fill_memory
	or	a
	ret

;----------------------------------------------------------
;build partition message from data
;in
;	HL : partiotn data
build_partiton_msg:
;number
	add	a,'A'
	ld	(msg_part_num),a
;bootselect
	ld	de,msg_devname+3
;preset inactive part
	ex	de,hl
	ld	a,'-'
	ld	(hl),a
	dec	hl
	ld	(hl),a
	dec	hl
	ld	(hl),a
	dec	hl
;boot_select , driver assoig
	ld	(hl),' '
	ld	a,(de)		;O_PPT_ACTIVE
	inc	de
	bit	7,a			;O_PPT_ACTIVE[7]    : boot select
	jr	z,$+4
	ld	(hl),'*'	;boot select
	inc	hl
;assing driver number
	and	0x0f		;O_PPT_ACTIVE[3..0] : drive number
	or	a
	jr	z,inactive_part
;1-4 assigned , 5-10 reserved
	cp	5
	jr	c,build_part_assigned
;5-15 F-KEY sub-partition
	dec	hl
	ld	(hl),'-'	;noboot
	inc	hl
;

	ld	c,' '
	add	a,'0'
	ld	b,a
	cp	'9'+1
	jr	c,part_f09
	ld	b,'1'
	sub	10
	ld	c,a
part_f09:
	ld	(hl),'P'
	inc	hl
	ld	(hl),b
	inc	hl
	ld	(hl),c
	jr	inactive_part
;
;1,2,3,4 assigned 
build_part_assigned:
	ld	(hl),'H'
	inc	hl
	ld	(hl),'D'
	inc	hl
build_part_num:
	add	a,'0'
	ld	(hl),a
inactive_part:
	ex	de,hl
;
	ld	de,msg_capa
	call	hex2asc4_hl
	ld	de,msg_id
	call	hex2asc2_hl
;
	ld	de,msg_tlun
	call	hex2asc2_hl
	ld	de,msg_tad2
	call	hex2asc6_hl
;
	ld	de,msg_slun
	call	hex2asc2_hl
	ld	de,msg_sad2
	call	hex2asc6_hl
;
	ret

;--------------------------------------------
hex2asc6_hl:
	call	hex2asc2_hl
hex2asc4_hl:
	call	hex2asc2_hl
hex2asc2_hl:
	ld	a,(hl)
	inc	hl
	jp	hex2asc2

;----------------------------------------------------------
;in
;	A  : data
;	HL : address
;	BC : size
;out
;	DE : next point
fill_memory_de_a_bc:
	ex	de,hl
fill_memory:
fill_memory_hl_a_bc:
	ld	(hl),a
	ld	e,l
	ld	d,h
	inc	de
	dec	bc
	ldir
	ret

;----------------------------------------------------------
;
msg_partition_item:
	db	"n| DEV|CAP.|ID|T.LUN_LAD|S.LUN_LAD|",13,0
;
msg_partition:
msg_part_num:
	db	" |"
msg_devname:
	db	"*HD0|"
msg_capa:
	db	"0000|"
msg_id:
	db	"00|"
msg_tlun:
	db	"00_"
msg_tad2:
	db	"000000|"
msg_slun:
	db	"00_"
msg_sad2:
	db	"000000|",13,0
;
B_HD_AUTOBOOT:
	db	0
B_HD_MAXDRIVE
	db	0
B_DISP_LEVEL:
	db	0

msg_pert_recocard_cantread:
	db	"HD partition recoard can't read",13,0
;

;----------------------------------------------------------
;partition table for PARTITON_RECOARD access
;HD1 for partition table
D_PARTITION_RAW:
	PARTITION_DATA	0, 0,0,0x000000, 0x000000,33
D_PARTITION_RAW_SIZE	equ	$-D_PARTITION_RAW

;----------------------------------------------------------
;default partition data
;	org	0xe600
;message
D_PARTITION_1E30:
	include	"partition_1e30.asm"
D_PARTITION_1E30_SIZE	equ	$-D_PARTITION_1E30
