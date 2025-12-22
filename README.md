# ZipChip

ZipChip is a CHIP-8 emulator written in Zig with a real-time renderer and audio playback powered by raylib. It aims to keep the code approachable for learners interested in virtual machines, graphics loops, and simple sound synthesis.

---

## Current Status

- The VM boots with the canonical fontset, loads CHIP-8 binaries into memory, and executes a large subset of the instruction matrix.
- A raylib window renders the 64×32 monochrome framebuffer at an arbitrary integer scale.
- Keyboard events are mapped to the CHIP-8 hexadecimal keypad layout.
- Delay and sound timers tick at 60 Hz; the CPU targets 700 instructions per second.
- A generated sine wave is streamed through raylib’s `AudioStream` whenever the sound timer is non-zero.
- Opcode tracing is enabled to help finalize instruction coverage.

---

## Implemented Features

- [x] **Complete VM state initialization**: 16 general-purpose registers, index register, stack pointer, timers, keypad, and 4 KB memory map seeded with the standard fontset at `0x50`.
- [x] **ROM loader with bounds checking**: Streams `.c8` binaries into interpreter memory starting at `0x200`, validating file size before allocation.
- [x] **Arena-backed allocations**: Uses `std.heap.ArenaAllocator` to make lifetime management explicit and deterministic.
- [x] **Opcode execution core**: Implements the majority of the CHIP-8 instruction set, including:
  - Flow control (`CLS`, `RET`, `JP`, `CALL`, `SE`, `SNE`, `SKP`, `SKNP`)
  - Register ops (`LD`, arithmetic/logic, shifts, BCD, bulk memory transfers)
  - Graphics drawing (`DRW`) with collision detection
  - Timers and random number generation (`LD DT/ST`, `RND`)
- [x] **Timing & rendering loop**: Synchronizes CPU and timer cadence independently and draws the framebuffer every frame.
- [x] **Keyboard input mapping**: Translates PC keyboard keys (`1`–`4`, `Q`–`V`) to the CHIP-8 keypad (`0x0`–`0xF`).

---

## Prerequisites

- **Zig** `0.15.2` or newer
- **raylib** development libraries installed on your system
  - On Linux you can typically install via your package manager (e.g., `sudo pacman -S raylib` or `sudo apt install libraylib-dev`)
  - Ensure the headers and library files are discoverable by your compiler/linker

---

## Building

```bash
zig build
# optional convenience steps
zig build check   # fast validation build
zig build test    # runs tests (imports main for now)
```

The emulator binary is produced at `zig-out/bin/ZipChip`.

---

## Running

Execute the built binary directly or forward args through `zig build run` (the program expects exactly two arguments and prints `Usage: zch8 <scale> <rom>` if they are missing or invalid):

```bash
./zig-out/bin/ZipChip <scale> <path-to-rom>
# or
zig build run -- <scale> <path-to-rom>
```

- `<scale>`: integer pixel multiplier (e.g., `10` → 640×320 window).
- `<path-to-rom>`: path to a CHIP-8 ROM (`.ch8`). Sample ROMs live in `roms/` (e.g., `roms/1-chip8-logo.ch8`, `roms/5-quirks.ch8`).

On invalid scale or missing ROM, the app prints a diagnostic and exits gracefully.

---

## Controls

| CHIP-8 Key            | Keyboard |
| --------------------- | -------- |
| `0x1 0x2 0x3 0xC`     | `1 2 3 4` |
| `0x4 0x5 0x6 0xD`     | `Q W E R` |
| `0x7 0x8 0x9 0xE`     | `A S D F` |
| `0xA 0x0 0xB 0xF`     | `Z X C V` |

---

## Project Layout

```text
ZipChip/
├── src/
│   ├── main.zig       # App entry, renderer, input, audio loop
│   ├── chip8.zig      # Emulator core: memory, opcodes, timers, framebuffer
│   ├── tonegen.zig    # Simple sine-wave generator for sound timer beeps
│   └── tests.zig      # Placeholder tests (imports main)
├── build.zig          # Zig build pipeline and steps (run, check, test)
├── build.zig.zon      # Package metadata and raylib_zig dependency
├── LICENSE            # MIT license
├── README.md          # Project documentation (this file)
├── .gitignore
├── zig-out/           # Build outputs
├── roms/              # Example CHIP-8 ROMs
└── *.ch8              # Additional ROMs you add yourself
```

---

## Development Notes

- **Opcode tracing**: Each cycle logs `Debug: Opcode called: 0x...`. Gate or remove for release builds.
- **Timer cadence**: `target_instructions_per_second` and `target_timer_hz` live in `main.zig`. Tuning affects ROM compatibility.
- **Rendering**: Framebuffer stored as `64*32` `u32`s; pixels toggle via XOR to preserve collision semantics.
- **Audio**: `tonegen.zig` generates a short sine buffer; the sound timer drives start/stop of an `AudioStream`. Ensure your platform audio is configured.
- **Memory safety**: Bounds checks protect the program counter and ROM loading; errors propagate via Zig error unions.

---

## Roadmap

- [ ] Complete remaining CHIP-8 opcodes (scrolling variants, `0x00CN`, `0x00FB`, `0xFX75`, `0xFX85`, etc.) and validate against reference ROMs.
- [ ] Add configurable flags (disable opcode logging, set CPU frequency, toggle audio).
- [ ] Integrate raygui for runtime ROM selection and emulator controls.
- [ ] Expand automated tests for opcode units and integration scenarios.
- [ ] Provide platform-specific build notes (Windows/macOS) and packaging guidance.

---

## License

This project is licensed under the [MIT License](LICENSE). You are free to use, modify, and distribute the emulator in accordance with the license terms.
