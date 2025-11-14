# ZipChip

ZipChip is a work-in-progress [CHIP-8](https://en.wikipedia.org/wiki/CHIP-8) emulator written in [Zig](https://ziglang.org/). The goal of the project is to explore emulator design in a modern systems language while keeping the codebase approachable for learners interested in low-level development, virtual machines, and Zig itself.

---

## Features

- ✅ **Core virtual machine state**: 16 general-purpose registers, index register, stack, program counter, timers, and keypad state.
- ✅ **Memory initialization**: Fonts are preloaded at the canonical address `0x50`, with program memory beginning at `0x200`.
- ✅ **ROM loading pipeline**: Reads `.c8` binaries into the interpreter memory space with bounds validation.
- ✅ **Instruction scaffolding**: Implementations for `CLS`, `RET`, `JP`, and `CALL` opcodes as a foundation for the remaining instruction set.
- ✅ **Arena-backed allocations**: Uses `std.heap.ArenaAllocator` to make memory management explicit and easy to reason about.

> The emulator currently focuses on correctness and architecture; a renderer, input handling, and the full opcode matrix are on the roadmap.

---

## Getting Started

### Prerequisites

- Zig `0.15.2` or newer (matches the project’s `build.zig.zon` minimum)
- A CHIP-8 ROM (`.c8` file) to experiment with

You can verify your Zig installation with:

``` bash
zig version
```

### Build

``` bash
cd ZipChip
zig build
```

This command compiles the executable and installs it into `zig-out/bin/ZipChip`.

### Run

``` bash
cd ZipChip
zig build run
```

The current entry point prints a diagnostic message and attempts to load a placeholder ROM (`dummy.c8`). Replace this with an actual ROM path as the emulator matures.

### Test

``` bash
cd ZipChip
zig build test
```

The test suite bootstraps `src/main.zig` and ensures the codebase is free of compile-time regressions. As additional functionality lands, this will expand to include opcode and system-level tests.

---

## Project Layout

``` bash
ZipChip/
├── src/
│   ├── main.zig      # Application entry point
│   ├── chip8.zig     # Emulator core implementation
│   └── tests.zig     # Aggregated test entry
├── build.zig         # Zig build pipeline
├── build.zig.zon     # Package metadata (name, version, dependencies)
├── LICENSE           # MIT license
└── README.md         # Project documentation (this file)
```

---

## Development Notes

- **Memory Model**: The interpreter reserves 4 KB of memory (`[4096]u8`), aligning with the original CHIP-8 specification. Fonts are injected during initialization, and programs are loaded from `0x200`.
- **Instruction Fetching**: Each opcode is 2 bytes (`instruction_size = 2`). As more opcodes are added, `opcode` decoding will branch into dedicated handler functions.
- **Randomness**: The emulator uses Zig’s `std.crypto.random` for the `RND` opcode (yet to be implemented).
- **Error Handling**: Custom errors like `StackUnderflow` and `StackOverflow` surface fault conditions during stack manipulation, aiding debugging.

---

## Roadmap

- [ ] Complete opcode implementation and decoder
- [ ] Integrate a timing loop that respects delay/sound timers
- [ ] Add a renderer (e.g., SDL, Raylib, or a Zig-native backend)
- [ ] Provide keyboard input mapping
- [ ] Expand tests to cover individual instructions
- [ ] Add tooling for ROM selection and execution profiles

Suggestions and contributions are welcome! Feel free to open issues or submit pull requests as the emulator evolves.

---

## License

This project is licensed under the [MIT License](LICENSE). You are free to use, modify, and distribute the emulator in accordance with the license terms.
