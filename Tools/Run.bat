@echo off

call "C:\Program Files\qemu\qemu-system-x86_64.exe" -hda \\192.168.0.106\zlozka\Trinix.img -m 1024 -boot c
pause