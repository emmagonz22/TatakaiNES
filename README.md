# TatakaiNES

A fighting platform game developed for the Nintendo Entertainment System (NES) using 6502 Assembly.

## About

TatakaiNES is a side-scrolling fighting game that combines platform-style gameplay with combat mechanics. Built entirely in 6502 Assembly for authentic NES hardware and emulators.

## Features

- Side-scrolling platform fighting game
- Fluid character animations and movement
- Platform collision detection
- Classic NES visual style
- Responsive controls for jumps and combat

## Technical Details

- Developed using 6502 Assembly language
- Uses standard NES memory mapping
- Split into logical modules (Movement, Animation, Background, etc.)
- Custom sprite and background rendering

## Getting Started

### Prerequisites

To build and run this project, you'll need:

1. **ca65 Assembler and ld65 Linker** (Part of cc65 toolchain)
   - Download from: https://cc65.github.io/
   - Add to your system PATH

2. **NES Emulator**
   - Recommended: FCEUX (http://www.fceux.com/web/home.html) or 
   - Nestopia (http://nestopia.sourceforge.net/)
   - Mesen

### Building the Project

1. Clone this repository:
   ```bash
   git clone https://github.com/yourusername/TatakaiNES.git
   cd TatakaiNES
   ```

2. Assemble and link:
   ```bash
   ca65 src/main.asm -o main.o
   ld65 main.o -o tatakaines.nes -C nes.cfg
   ```

3. Run the ROM in your emulator:
   ```bash
   fceux tatakaines.nes
   ```

## Project Structure

```
TatakaiNES/
├── src/
│   ├── Movimiento/      # Movement and physics code
│   ├── Animacion/       # Character animation logic
│   ├── Fondo/           # Background rendering
│   ├── Personajes/      # Character definitions
│   └── header.inc       # ROM header configuration
├── assets/
│   └── graphics.chr     # Character graphics data
└── README.md            # Documentation
```

## Controls

- **D-Pad Left/Right**: Move character
- **D-Pad Up**: Jump
- **A Button**: Primary attack
- **B Button**: Secondary attack/Special move

## Memory Map

The game uses standard NES memory mapping:
- **$0000-$07FF**: RAM
- **$2000-$2007**: PPU registers
- **$4000-$4017**: APU and I/O registers

## Authors

- Emmanuel Gonzalez Morales
- Jorge Torres Muñiz

## License

This project is licensed under the MIT License - see the LICENSE file for details.