;----------------------------------------------------------
;MZ-2500 enhanced SASI : partition table data
;MZ-1E30 compatible partiton
;----------------------------------------------------------

;----------------------------------------------------------
;
IF1E30_ID		equ		0	;0..7
IF1E30_HD12_LUN	equ 	0	;0..7
IF1E30_HD34_LUN	equ 	1	;0..7
;
IF1E30_DRV_SIZE		equ 	1252*32	;(1215*33 -31)	;each drive
;top LAD
IF1E30_DRV0_TOP		equ	1*33
IF1E30_DRV0_DEAD	equ	IF1E30_DRV0_TOP+IF1E30_DRV_SIZE
IF1E30_DRV1_TOP		equ	(1+1215)*33
IF1E30_DRV1_DEAD	equ	IF1E30_DRV1_TOP+IF1E30_DRV_SIZE
IF1E30_ALTT_TOP		equ	(1+1215+1215)*33
IF1E30_ALTT_END		equ	(662*4)*33	;reserved zone
IF1E30_SAFE_LAD		equ	(663*4)*33	;HEAD RETRACT cy. 633
;special sector assign
IF1E30_ID_SECTOR	equ	0	;signature
IF1E30_ID_ALTT_INFO	equ	1	;alternate track info.

;----------------------------------------------------------
;ZERO TRACK
;	PARTITION_DATA	0,IF1E30_ID,IF1E30_HD12_LUN,0, 0,33
;HD1
	PARTITION_DATA	0x81,IF1E30_ID,IF1E30_HD12_LUN,IF1E30_SAFE_LAD, IF1E30_DRV0_TOP , IF1E30_DRV_SIZE
;	PARTITION_DATA	0   ,IF1E30_ID,IF1E30_HD12_LUN,IF1E30_SAFE_LAD, IF1E30_DRV0_DEAD, IF1E30_DRV1_TOP - IF1E30_DRV0_DEAD
;HD2
	PARTITION_DATA	0x02,IF1E30_ID,IF1E30_HD12_LUN,IF1E30_SAFE_LAD, IF1E30_DRV1_TOP , IF1E30_DRV_SIZE
;	PARTITION_DATA	0   ,IF1E30_ID,IF1E30_HD12_LUN,IF1E30_SAFE_LAD, IF1E30_DRV1_DEAD, IF1E30_ALTT_TOP - IF1E30_DRV1_DEAD
;alternate track
;	PARTITION_DATA	0   ,IF1E30_ID,IF1E30_HD12_LUN,IF1E30_SAFE_LAD, IF1E30_ALTT_TOP  , IF1E30_ALTT_END-IF1E30_ALTT_TOP
;safe cylinder
;	PARTITION_DATA	0   ,IF1E30_ID0,0,IF1E30_SAFE_LAD, IF1E30_ALTT_END  , 33*4
;retract cylinder
;	PARTITION_DATA	0,IF1E30_ID,IF1E30_HD12_LUN,0, 0,33
;
;ZERO TRACK
;	PARTITION_DATA	0,IF1E30_ID,IF1E30_HD34_LUN,0, 0,33
;HD3
	PARTITION_DATA	0x03,IF1E30_ID,IF1E30_HD34_LUN,IF1E30_SAFE_LAD, IF1E30_DRV0_TOP , IF1E30_DRV_SIZE
;	PARTITION_DATA	0   ,IF1E30_ID,IF1E30_HD34_LUN,IF1E30_SAFE_LAD, IF1E30_DRV0_DEAD, IF1E30_DRV1_TOP - IF1E30_DRV0_DEAD
;HD4
	PARTITION_DATA	0x04,IF1E30_ID,IF1E30_HD34_LUN,IF1E30_SAFE_LAD, IF1E30_DRV1_TOP , IF1E30_DRV_SIZE
;	PARTITION_DATA	0   ,IF1E30_ID,IF1E30_HD34_LUN,IF1E30_SAFE_LAD, IF1E30_DRV1_DEAD, IF1E30_ALTT_TOP - IF1E30_DRV1_DEAD
;alternate track
;	PARTITION_DATA	0   ,IF1E30_ID,IF1E30_HD34_LUN,IF1E30_SAFE_LAD, IF1E30_ALTT_TOP  , IF1E30_ALTT_END-IF1E30_ALTT_TOP
;safe cylinder
;	PARTITION_DATA	0   ,IF1E30_ID0,0,IF1E30_SAFE_LAD, IF1E30_ALTT_END  , 33*4
;retract cylinder
;	PARTITION_DATA	0   ,IF1E30_ID0,IF1E30_SAFE_LAD, IF1E30_SAFE_LAD  , 33*4
