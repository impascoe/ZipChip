# ZipChip

ZipChip is a [CHIP-8](https://en.wikipedia.org/wiki/CHIP-8) emulator written in [Zig](https://ziglang.org/) with a real-time renderer powered by [raylib](https://www.raylib.com/). The project is an exploration of emulator architecture in a modern systems language while keeping the code approachable for learners interested in virtual machines, graphics loops, and systems programming.

---

## Current Status

- The virtual machine boots with the canonical fontset, loads CHIP-8 binaries into memory, and steps through a large subset of the instruction matrix.
- A raylib-backed window displays the 64×32 monochrome framebuffer at an arbitrary integer scale.
- Keyboard events are mapped to the CHIP-8 hexadecimal keypad layout.
- Delay and sound timers tick at 60 Hz, while the CPU targets 500 instructions per second.
- Opcode debugging is enabled to help trace execution while the instruction coverage is finalized.

---

## Implemented Features

- [x] **Complete VM state initialization**: 16 general-purpose registers, index register, stack pointer, timers, keypad, and 4 KB memory map seeded with the standard fontset at `0x50`.
- [x] **ROM loader with bounds checking**: Streams `.c8` binaries into interpreter memory starting at `0x200`, validating file size before allocation.
- [x] **Arena-backed allocations**: Uses `std.heap.ArenaAllocator` to make lifetime management explicit and deterministic.
- [x] **Opcode execution core**: Implements the majority of the CHIP-8 instruction set, including:
  - Flow control (`CLS`, `RET`, `JP`, `CALL`, `SE`, `SNE`, `SKP`, `SKNP`)
  - Register operations (`LD`, arithmetic/logic, bit shifts, BCD, bulk memory transfers)
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

``` bash
zig build
```

This command produces the emulator binary at `zig-out/bin/ZipChip`.

---

## Running

Execute the built binary directly or forward arguments through `zig build run`:

``` bash
./zig-out/bin/ZipChip <scale> <path-to-rom>
# or
zig build run -- <scale> <path-to-rom>
```

- `<scale>` is an integer pixel multiplier (e.g., `10` for a 640×320 window).
- `<path-to-rom>` is the path to a CHIP-8 ROM file (`.c8`).

If the emulator cannot parse the scale or locate the ROM, it prints a diagnostic message and exits gracefully.

---

## Controls

| CHIP-8 Key | Keyboard |
| ---------- | -------- |
| `0x1 0x2 0x3 0xC` | `1 2 3 4` |
| `0x4 0x5 0x6 0xD` | `Q W E R` |
| `0x7 0x8 0x9 0xE` | `A S D F` |
| `0xA 0x0 0xB 0xF` | `Z X C V` |

---

## Project Layout

```text
ZipChip/
├── src/
│   ├── main.zig      # Application entry point, renderer, and input loop
│   └── chip8.zig     # Emulator core, memory, and opcode implementations
├── build.zig         # Zig build pipeline
├── build.zig.zon     # Package metadata (name, version, dependencies)
├── LICENSE           # MIT license
└── README.md         # Project documentation (this file)
```

---

## Development Notes

- **Opcode tracing**: Every emulation cycle logs the fetched opcode (`Debug: Opcode called: 0x...`). This is invaluable while validating ROM behavior; remove or gate the print when running release builds.
- **Timer cadence**: CPU and timer frequencies are configurable constants (`target_instructions_per_second`, `target_timer_hz`). Adjust them cautiously to preserve ROM compatibility.
- **Rendering**: The framebuffer is stored as a `64*32` array of `u32`. Pixels are toggled via XOR, mirroring the original CHIP-8 collision semantics.
- **Memory safety**: Bounds checks guard the program counter and ROM loading. Errors propagate via Zig’s `error` union types, making fault conditions explicit.

---

## Roadmap

- [ ] Finish the remaining CHIP-8 opcodes (`0x00CN`, `0x00FB`, `0xFX75`, etc.) and verify behavior against reference ROMs.
- [ ] Implement audible feedback when the sound timer is non-zero.
- [ ] Add configuration flags (e.g., disable opcode logging, set CPU frequency).
- [ ] Integrate `raygui` for runtime ROM selection and emulator controls.
- [ ] Introduce automated tests for individual opcodes and integration scenarios.
- [ ] Provide build instructions for additional platforms (Windows/macOS) and package formats.

---

## License

This project is licensed under the [MIT License](LICENSE). You are free to use, modify, and distribute the emulator in accordance with the license terms.
