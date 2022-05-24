;----------------------------------------------------------
;MZ-2500 enhanced SASI : partition table define
;----------------------------------------------------------

;----------------------------------------------------------
;partition recoard no.
PARTITON_RECOARD	equ	0x000003

;----------------------------------------------------------
;partition data offset
O_PPT_CTRL	equ	0		;DRV  : CTRL byte for READ/WRITE
O_PPT_ACTIVE	equ	O_PPT_CTRL	;FILE : bit[7]=boot,bit[3..0]=drive number
O_PPT_CAPA_H	equ	1		;drive capacity
O_PPT_CAPA_L	equ	2
O_PPT_SASIID	equ	3		;SASI-ID
O_PPT_TOP_LUN	equ	4		;LUN
O_PPT_TOP_LAD2	equ	5		;TOP LogicalAddress
O_PPT_TOP_LAD1	equ	6
O_PPT_TOP_LAD0	equ	7
O_PPT_SAFE_LUN	equ	8		;LUN for safe zone
O_PPT_SAFE_LAD2	equ	9		;LAD for safe zone
O_PPT_SAFE_LAD1	equ	10
O_PPT_SAFE_LAD0	equ	11
O_PPT_RSV_0C	equ	12		;reserved (assigned iseg)
O_PPT_RSV_0D	equ	13		;reserved (assigned drive number)
O_PPT_RSV_0E	equ	14
O_PPT_RSV_0F	equ	15

;----------------------------------------------------------
;partition table generate macro

PARTITION_DATA_SIZE	equ	16

PARTITION_DATA	macro	_ACTIVE_,_ID_,_LUN_,_SAFE_,_TOP_,_CAPACITY_
	db	_ACTIVE_		;+00:CTRL(option) / ACTIVE_NO
	db	(_CAPACITY_)/256	;+01:capacityT
	db	(_CAPACITY_)		;+02:capacity0
	db	0x01 << _ID_		;+03:SASI-ID
	db	(_LUN_*0x20)		;+04:top_lba3/LUN
	db	(_TOP_)/0x10000		;+05:top_lba2
	db	(_TOP_)/0x100		;+06:top_lba1
	db	(_TOP_)			;+07:top_lba0
	db	(_LUN_*0x20)		;+08:top_lba3/LUN
	db	_SAFE_/0x10000		;+09:top_lba2
	db	_SAFE_/0x100		;+0A:top_lba1
	db	_SAFE_			;+0B:top_lba0
	db	0,0,0,0			;reserve
	endm

