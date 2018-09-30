# matrix-rain.gb

A [Matrix rain effect](https://en.wikipedia.org/wiki/Matrix_digital_rain) for the Game Boy, written in LR35902 (Z80-like) assembler

<img src="https://user-images.githubusercontent.com/1031558/46263385-0de4a800-c4d4-11e8-90dd-e6175615cca6.gif" width="320" height="288">

## Demonstrates

* Memory write batching to optimize vblank utilization
* DMA transfer
* Look-up tables

## Building

The Game Boy assembler [RGBDS](https://github.com/rednex/rgbds/) is needed.

### Linux/Mac OS

Build and install as specified on the `RGBDS` project site.

Run `make`

### Windows

From the shell for the [Windows Subsystem for Linux](https://docs.microsoft.com/en-us/windows/wsl/install-win10), install `RGBDS`.

Run either `make` from the WSL shell or `wsl make` from PowerShell.

### Output

Build targets are created in folder `build`. These include:

* rom file `matrix-rain.gb`
* debug symbols

## Tools

* [RGBDS Z80](https://github.com/DonaldHays/rgbds-vscode) VS Code extension

* [BGB](http://bgb.bircd.org/) emulator/debugger for the Game Boy

## Resources

* [Awesome Game Boy Development](https://github.com/avivace/awesome-gbdev)
