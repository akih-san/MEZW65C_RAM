del *.lst
del *.obj
del *.map
del *.sym
del *.BIN
WDC816AS -G -L m816_body.asm
WDC816AS -G -L m816_io.asm
WDCLN -HB -g -t -CF300 m816_io.obj m816_body.obj
bin2mot -LD00 -IF300 m816_io.bin aaa.s
mot2bin aaa.s MON816.BIN
copy MON816.BIN ..\DISKS\.
del aaa.s
del m816_io.bin
