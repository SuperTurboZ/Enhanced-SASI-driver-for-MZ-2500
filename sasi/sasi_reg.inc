;MZ-2500 , MZ-1E30 I/O assign

;HW assign
IO_SASI_DATA	equ 0xA4
IO_SASI_CTRL	equ 0xA5
IO_SASI_SELID	equ IO_SASI_DATA
IO_SASI_STS     equ IO_SASI_CTRL
;
BIT_SASI_S_REQ	equ 7
BIT_SASI_S_ACK	equ 6
BIT_SASI_S_BSY	equ 5
BIT_SASI_S_MSG	equ 4
BIT_SASI_S_C_ND	equ 3
BIT_SASI_S_I_NO	equ 2
BIT_SASI_S_INT	equ 0
;
BM_SASI_REQ	equ 1<<BIT_SASI_S_REQ
BM_SASI_ACK	equ 1<<BIT_SASI_S_ACK
BM_SASI_BSY	equ 1<<BIT_SASI_S_BSY
BM_SASI_MSG	equ 1<<BIT_SASI_S_MSG
BM_SASI_C_ND	equ 1<<BIT_SASI_S_C_ND
BM_SASI_I_NO	equ 1<<BIT_SASI_S_I_NO
BM_SASI_INT	equ 1<<BIT_SASI_S_INT
;
BIT_SASI_C_SEL	equ 5
BIT_SASI_C_RST	equ 3
BIT_SASI_C_DAME	equ 1
BIT_SASI_C_INTE	equ 0
;CTRL value
SASI_C_SEL_ON	equ 0x20
SASI_C_SEL_OFF	equ 0x00
;SASI_C_RST_ON	equ 0x08
SASI_C_RST_ON	equ 0x48  ;takedasann
SASI_C_RST_OFF	equ 0x00

;sasi status phase
SASI_STS_BFREE	equ 0
SASI_STS_CMD	equ             BM_SASI_C_ND             |BM_SASI_BSY
SASI_STS_DIN	equ                          BM_SASI_I_NO|BM_SASI_BSY
SASI_STS_DOUT	equ                                       BM_SASI_BSY
SASI_STS_STSIN	equ             BM_SASI_C_ND|BM_SASI_I_NO|BM_SASI_BSY
SASI_STS_MSGIN	equ BM_SASI_MSG|BM_SASI_C_ND|BM_SASI_I_NO|BM_SASI_BSY

;combine status/mask
SASI_STS_DATA	equ SASI_STS_DIN
SASI_STS_MCBR	equ BM_SASI_MSG|BM_SASI_C_ND|BM_SASI_BSY|BM_SASI_REQ
SASI_STS_MCIB	equ BM_SASI_MSG|BM_SASI_C_ND|BM_SASI_I_NO|BM_SASI_BSY
SASI_STS_MCIBR	equ SASI_STS_MCIB|BM_SASI_REQ
SASI_STS_MCIBRA	equ SASI_STS_MCIBR|BM_SASI_ACK

;timeout 
SASI_DEFUALT_TIMEOUT_CNT	equ	3*0x10000
SASI_SEEK_TIMEOUT_CNT		equ	20*0x10000  ;more 10 seconds.
;cause seek alternate-track
SASI_DATA_TIMEOUT_CNT		equ	SASI_SEEK_TIMEOUT_CNT
;
SASI_DATA_TIMEOUT_HM		equ	(SASI_DATA_TIMEOUT_CNT+255)/256
SASI_DATA_TIMEOUT_L		equ	(SASI_DATA_TIMEOUT_CNT & 255)
;
SASI_DEFUALT_TIMEOUT_H		equ	SASI_DEFUALT_TIMEOUT_CNT/0x10000
SASI_SEEK_TIMEOUT_H     	equ SASI_SEEK_TIMEOUT_CNT/0x10000

;macro
SASI_SEL_ON_A  macro
  out (IO_SASI_SELID),a
  ld  a,SASI_C_SEL_ON
  out (IO_SASI_CTRL),a
  endm
  
SASI_SEL_OFF macro
  ld	a,0		;keep flag
  out (IO_SASI_CTRL),a
  endm
 
SASI_RST_ON  macro
  ld  a,SASI_C_RST_ON
  out (IO_SASI_CTRL),a
  endm
  
SASI_RST_OFF macro
  ld	a,0		;keep flag
  out (IO_SASI_CTRL),a
  endm