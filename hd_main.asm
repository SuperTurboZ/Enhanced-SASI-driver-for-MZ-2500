;----------------------------------------------------------
;MZ-2500 EH-SASI : main programs
;----------------------------------------------------------

;----------------------------------------------------------
;include
;	.nolist
	include	"iocs.inc"
	include	"sasi/sasi_reg.inc"
	include	"sasi_param.inc"
;	.list
;----------------------------------------------------------
;overlay block : MISC
	include	"hd_ovl_misc.asm"
;----------------------------------------------------------
;common block
	include	"hd_common.asm"
;----------------------------------------------------------
;IPL-FCB , IPL program & installer
	include	"hd_install.asm"
;----------------------------------------------------------
