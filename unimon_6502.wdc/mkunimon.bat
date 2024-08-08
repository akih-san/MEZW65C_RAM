del *.lst
del *.obj
del *.map
del *.sym
del *.BIN
WDC02AS -G -L unimon_6502.asm
WDCLN -HB -g -t unimon_6502.obj
bin2mot -L800 -IF800 unimon_6502.bin aaa.s
mot2bin aaa.s UMON_W65.BIN
copy UMON_W65.BIN ..\DISKS\.
del aaa.*
del unimon_6502.bin

