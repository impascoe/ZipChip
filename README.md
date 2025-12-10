# ZipChip

ZipChip is a CHIP-8 emulator written in Zig with a real-time renderer and audio playback powered by raylib. It aims to keep the code approachable for learners interested in virtual machines, graphics loops, and simple sound synthesis.

---

## Current Status

- The VM boots with the canonical fontset, loads CHIP-8 binaries into memory, and executes a large subset of the instruction matrix.
- A raylib window renders the 64×32 monochrome framebuffer at an arbitrary integer scale.
- Keyboard events are mapped to the CHIP-8 hexadecimal keypad layout.
- Delay and sound timers tick at 60 Hz; the CPU targets 500 instructions per second.
- A generated sine wave is streamed through raylib’s `AudioStream` whenever the sound timer is non-zero.
- Opcode tracing is enabled to help finalize instruction coverage.

---

## Implemented Features

- ✅ **Complete VM state initialization**: 16 general-purpose registers, index register, stack pointer, timers, keypad, and 4 KB memory map seeded with the standard fontset at `0x50`.
- ✅ **ROM loader with bounds checking**: Streams `.c8` binaries into interpreter memory starting at `0x200`, validating file size before allocation.
- ✅ **Arena-backed allocations**: Uses `std.heap.ArenaAllocator` for explicit lifetime management.
- ✅ **Opcode execution core**: Implements the majority of the CHIP-8 instruction set, including:
  - Flow control (`CLS`, `RET`, `JP`, `CALL`, `SE`, `SNE`, `SKP`, `SKNP`)
  - Register ops (`LD`, arithmetic/logic, shifts, BCD, bulk memory transfers)
  - Graphics drawing (`DRW`) with collision detection
  - Timers and randomness (`LD DT/ST`, `RND`)
- ✅ **Timing & rendering loop**: Independent CPU/timer cadence; draws the framebuffer every frame.
- ✅ **Keyboard input mapping**: PC keys (`1`–`4`, `Q`–`V`) to CHIP-8 keypad (`0x0`–`0xF`).
- ✅ **Audio output**: Generates a 440 Hz sine wave (`tonegen.zig`) and streams it via raylib; starts/stops based on the CHIP-8 sound timer.

---

## Prerequisites

- **Zig** `0.15.2` or newer (matches `build.zig.zon`).
- **raylib** development libraries on your system (headers + shared libs).
  - Linux examples: `sudo pacman -S raylib` or `sudo apt install libraylib-dev`.
- Audio output device accessible to raylib (for the sound timer beep).

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

Execute the built binary directly or forward args through `zig build run`:

```bash
./zig-out/bin/ZipChip <scale> <path-to-rom>
# or
zig build run -- <scale> <path-to-rom>
```

- `<scale>`: integer pixel multiplier (e.g., `10` → 640×320 window).
- `<path-to-rom>`: path to a CHIP-8 ROM (`.c8`). A few sample ROMs are included in the repo root (`1-chip8-logo.ch8`, `2-ibm-logo.ch8`, etc.).

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
└── *.ch8              # Example CHIP-8 ROMs
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

This project is licensed under the [MIT License](LICENSE). You are free to use, modify, and distribute the emulator under the license terms.