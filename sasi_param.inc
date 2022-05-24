;----------------------------------------------------------
;MZ-2500 enhanced SASI : driver parameter
;----------------------------------------------------------

;----------------------------------------------------------
;build switch

;CPLフラグのサポート(P-CP/M +FDD emu boot対応)
ENABLE_CPLFLG	equ	0

;DRIVEパラメータに zch 参照(P-CP/M +FDD emu boot対応)
FIX_DRIVE_PARAMETER	equ	1

;----------------------------------------------------------
;HD device install point

;RSドライバをリストの後ろにどかして、RSの位置にHDを登録する。(P-CP/M HDP不足対応）
HDD_DEV_PTR	equ	DEV_PTR_RS	;RS

;----------------------------------------------------------
;'HD:' partation table
	include	"partition.inc"

;----------------------------------------------------------
;'ROM' device BLOCK allocation

;---------- IPL recoard
ROM_LBA_IPL_INFO	equ	0x00	;MZ IPL INFO,Copyright,Licence
;---------- installer , partiton load
ROM_LBA_IPL_PROGRAM	equ	0x00	;0x8000-0x87FF -> 0xE000-0xE7FF
;---------- driver common block (0x0F00-0x0FFF)
ROM_LBA_COMMON		equ	0x08
;---------- driver overlay block (0x0C20-0x0CBF)
ROM_LBA_DATAIN		equ	0x09	;DATA_IN -> busfree
ROM_LBA_DATAOUT		equ	0x0A	;DATA_OUT-> busfree
ROM_LBA_MISC		equ	0x0B	;miscellaneous
ROM_LBA_RW_CMD		equ	0x0C	;READ/WRTIE
ROM_LBA_RETRACT		equ	0x0D	;RETRACT(seek)
;---------- MZ FileSystem
ROM_LBA_BITMAP		equ	0x0F	;File Allocate Data
ROM_LBA_DIRECTORY	equ	0x10	;File Directory
ROM_LBA_DATABLOCK	equ	0x18	;File Data

;----------------------------------------------------------
;MEMORY map : transfer code overlay block

SASI_OVL_CODE_TOP	equ	buff3
SASI_OVL_CODE_SIZE	equ	buff3_size-16	;reserve 16bytes for parameter

;overlay grobal parameter block
SASI_PARAMETER		equ	buff3 + SASI_OVL_CODE_SIZE

;transfer paramter
W_SASI_MEM_ADDR		equ	SASI_PARAMETER+0
W_SASI_DATA_SIZE	equ	SASI_PARAMETER+2
;result
W_SASI_END_ADDR		equ	SASI_PARAMETER+4

;SASI command
D_SASI_CMD6		equ	SASI_PARAMETER+8
B_SASI_CMD6_CMD		equ	D_SASI_CMD6+0
B_SASI_CMD6_LUN_LAD2	equ	D_SASI_CMD6+1
B_SASI_CMD6_LAD1	equ	D_SASI_CMD6+2
B_SASI_CMD6_LAD0	equ	D_SASI_CMD6+3
B_SASI_CMD6_NOB		equ	D_SASI_CMD6+4
B_SASI_CMD6_CTRL	equ	D_SASI_CMD6+5
;result
B_SASI_STS    		equ	SASI_PARAMETER+14
B_SASI_MSG		equ	SASI_PARAMETER+15

;----------------------------------------------------------
;MEMORY map : common block

SASI_COMMON_CODE_TOP	equ	0x0f00

hd_device_descripter	equ	SASI_COMMON_CODE_TOP

;GROBAL ENTRY point
;SASI_COMMON_INKEY_HOOK  equ hd_device_descripter+0x19+0x40

COMMON_PARAMETER  equ 0x1000	;deleted

;----------------------------------------------------------
;MEMORY map : overlay  MISC
;
ovl_misc_partsig equ buff3+0x00
ovl_misc_error_a equ buff3+0x10

;----------------------------------------------------------
;MEMORY map : overlay read/write command
ovl_cmdrw_cmd6	equ	buff3+0

;----------------------------------------------------------
;MEMORY map : overlay retract(seek)
ovl_retract_cmd6	equ	buff3+0
