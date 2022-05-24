;----------------------------------------------------------------------------
;MZ-2500 IOCS define for Device Driver
;----------------------------------------------------------------------------

;--------------------------------------
;RST 18H SVC function number
MONOP		equ	0x00
SVC_CR1		equ	0x01
SVC_CR2		equ	0x02
SVC_CRT1C	equ	0x03
SVC_CRT1X	equ	0x04
SVC_CRTMS	equ	0x05
SVC_GETL	equ	0x0C	;
SVC_INKEY	equ	0x0D	;
SVC_BREAK	equ	0x0E	;ZF=1 SHIFT+BERAK
;
;SVC_ERRX	equ	0x1B
;
SVC_CHDIR	equ	0x3A
;
SVC_DEVNM	equ	0x2C
SVC_DFUNC	equ	0x42
;
SVC_IOSUB	equ	0x7B


;--------------------------------------
;register save support

;auto push/pop ix,bc,de,hl,af
pushra   	equ	0x0042

;auto push/pop ix,bc,de,hl
pushr   	equ	0x004E

;--------------------------------------
;I/O error entry
ioerr		equ	0x00AA

;--------------------------------------
;restore memory map & jump buff3(I/O transfer)
rwmap   	equ	0x028A

;--------------------------------------
;0500-051F : device descripter pointer list
;
DEV_PTR_FD  equ 0x0500 +0x02
DEV_PTR_CRT equ 0x0500 +0x04
DEV_PTR_KB  equ 0x0500 +0x06
DEV_PTR_LPT equ 0x0500 +0x08
DEV_PTR_USR equ 0x0500 +0x0A
DEV_PTR_RS  equ 0x0500 +0x0C
DEV_PTR_CMT equ 0x0500 +0x0E
DEV_PTR_QD  equ 0x0500 +0x10 ;reserved
DEV_PTR_MEM equ 0x0500 +0x12
DEV_PTR_EMM equ 0x0500 +0x14
DEV_PTR_ROM equ	0x0500 +0x16
;
DEV_PTR_12  equ 0x0500 +0x18
DEV_PTR_13  equ 0x0500 +0x1A
DEV_PTR_14  equ 0x0500 +0x1C
DEV_PTR_15  equ 0x0500 +0x1E

;--------------------------------------
vrfflg		equ	0x05C0	;0=on,1=off
cplflg    equ 0x05C1  ;bit0:compliment , bit1:density

;--------------------------------------
zch       equ 0x0846

;--------------------------------------
;current device descripter table
;
zarea	        equ	0x084A
zbytes		equ	0x19
;
zdevnum	        equ	zarea+0x00	
zflag1	        equ	zarea+0x04	
zflag2	        equ	zarea+0x05	
zdirmax		equ	zarea+0x06
zinit	        equ	zarea+0x07	
zro	        equ	zarea+0x09	
zwo	        equ	zarea+0x0B	
ziseg	        equ	zarea+0x0D	
zblk	        equ	zarea+0x0F	
zinp	        equ	zarea+0x11
zout	        equ	zarea+0x13
zfunc	        equ	zarea+0x15
zctrl	        equ	zarea+0x17

;--------------------------------------
;I/O transfer code buffer
buff3		equ	0x0c20
buff3_size	equ	0x00a0

;--------------------------------------
;free area (device driver space)
buff6		equ 0x0f00
buff6_size	equ 0x0100

;--------------------------------------
;IPL work area
lddsk		equ	0xf800
ldfasc		equ	0xf813	;boot num ascii code
logmo 		equ	0xf814
fdxd		equ	0xf816	;0x00=ROM,other=FD
