del *.lst
del *.obj
del *.map
del *.sym
del *.BIN
WDC02AS -G -L min_mon.asm
WDCLN -HB -g -t min_mon.obj
bin2mot -L2900 -ID700 min_mon.bin aaa.s
mot2bin aaa.s BASIC65.BIN
copy BASIC65.BIN ..\DISKS\.
del aaa.*
del min_mon.bin
