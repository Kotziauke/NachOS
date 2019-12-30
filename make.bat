@echo off
nasm-2.14\nasm BootLoader.asm -f bin -o BootLoader.bin
nasm-2.14\nasm System.asm -f bin -o System.bin
copy /b BootLoader.bin+System.bin NachOS.img > nul
del *.bin
pause
