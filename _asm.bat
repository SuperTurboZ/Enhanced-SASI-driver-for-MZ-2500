rem config
echo off
rem AASM V3.71+ <http://ldlabo.hishaku.com/NO41/hontai.htm>
set ASM=\tool\aasm\aasm -t20 -l 
set BHM=\tool\bhm\bhm
set EMUROM=..\..\FILE.ROM

rem pull file image
set target=rom_fs
echo Building ROM: FileSystem image '%target%'
%BHM% <%target%.bhm >%target%.log

rem version code
echo %	db	"20220524" >version.asm

rem OVL MODULE
set target=hd_ovl_tx
call :ASM

rem OVL MODULE
set target=hd_ovl_rx
call :ASM

rem OVL MODULE
set target=hd_ovl_retract
call :ASM

rem OVL MODULE
set target=hd_ovl_cmd_rw
call :ASM

rem IPL-FCB + OVL MISC + COMMON + INSTALLER
set target=hd_main
call :ASM

rem ROM IMAGE mapping
set target=rom\sasirom
echo Building final ROM image '%target%'
%BHM% <%target%.bhm >%target%.log

rem copy ROM file to emulator
copy %target%.bin %EMUROM%

rem END main
:EXIT
exit /b

:ASM
%ASM% %target%.asm -oout\%target%.hex >%target%.log
echo Assembled '%target%' : Result %errorlevel%
rem catch error
if "%errorlevel%"=="0" goto :EXIT
notepad %target%.log
exit /b
