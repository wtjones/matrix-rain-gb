rem TODO - replace this dumpster fire with a proper makefile

setlocal
ECHO off
set thispath=%cd%
IF NOT EXIST %thispath%\build mkdir %thispath%\build


rgbasm -i include/ -obuild\header.obj src\header.asm
rgbasm -i include/ -obuild\main.obj src\main.asm
rgbasm -i include/ -obuild\droplet.obj src\droplet.asm
rgbasm -i include/ -obuild\init.obj src\init.asm
rgbasm -i include/ -obuild\math.obj src\math.asm
rgbasm -i include/ -obuild\memory.obj src\memory.asm
rgbasm -i include/ -obuild\video.obj src\video.asm
rgblink -mbuild\matrix.map -nbuild\matrix.sym -obuild\matrix.gb ^
build\header.obj ^
build\main.obj ^
build\droplet.obj ^
build\init.obj ^
build\math.obj ^
build\memory.obj ^
build\video.obj

rgbfix -p0 -v build\matrix.gb

