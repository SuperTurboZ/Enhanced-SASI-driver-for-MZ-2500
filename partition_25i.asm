;----------------------------------------------------------
;MZ-2500 enhanced SASI : partition table data
;HD25I
;
;note:
;	HD0 = ID=0,LUN=0
;	HD1 = ID=0,LUN=1
;	2ドライブ仕様のようです。（かねごんさん動作検証）
	;
;	DRIVE容量の詳細は不明です
;----------------------------------------------------------
;----------------------------------------------------------
;HD25I fixed (unknown yet)

HD25I_ID		equ	0
HD25I_HD1_LUN		equ 	0x20*0
HD25I_HD2_LUN		equ 	0x20*1
;
HD25I_DRV_SIZE		equ 	1252*32	;(1215*33 -31)	;?
;top LAD
HD25I_TOP		equ	1*33		;?
HD25I_DEAD	equ	HD25I_DRV0_TOP+HD25I_DRV_SIZE ?
HD25I_ALTT_TOP		equ	(1+1215+1215)*33 ? 
HD25I_ALTT_END		equ	(662*4)*33	;reserved zone ?
HD25I_SAFE_LAD		equ	(663*4)*33	;HEAD RETRACT cy. 633 ?

;special sector assign
HD25I_ID_SECTOR		equ	0	;signature
HD25I_ID_ALTT_INFO	equ	1	;alternate track info ?

;----------------------------------------------------------
;ZERO TRACK
	PARTITION_DATA	0,0,0,0, 0,33
;HD1
	PARTITION_DATA	0x81,MZ1E30_ID,0,MZ1E30_SAFE_LAD, MZ1E30_DRV0_TOP , MZ1E30_DRV_SIZE
	PARTITION_DATA	0   ,MZ1E30_ID,0,MZ1E30_SAFE_LAD, MZ1E30_DRV0_DEAD, MZ1E30_DRV1_TOP - MZ1E30_DRV0_DEAD
;HD2
	PARTITION_DATA	0x02,MZ1E30_ID,0,MZ1E30_SAFE_LAD, MZ1E30_DRV1_TOP , MZ1E30_DRV_SIZE
	PARTITION_DATA	0   ,MZ1E30_ID,0,MZ1E30_SAFE_LAD, MZ1E30_DRV1_DEAD, MZ1E30_ALTT_TOP - MZ1E30_DRV1_DEAD
;alternate track
	PARTITION_DATA	0   ,MZ1E30_ID,0,MZ1E30_SAFE_LAD, MZ1E30_ALTT_TOP  , MZ1E30_ALTT_END-MZ1E30_ALTT_TOP
;safezone
;retract cylinder
;	PARTITION_DATA	0   ,MZ1E30_ID0,MZ1E30_SAFE_LAD, MZ1E30_SAFE_LAD  , 33*4
