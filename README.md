# CS61C — Great Ideas in Computer Architecture

> Solutions to the projects of UC Berkeley **CS61C** — a C snake game, a RISC-V
> assembly neural-network digit classifier, a Logisim pipelined CPU, and a
> SIMD/OpenMP matrix-convolution library — an independent, from-skeleton
> implementation, part of a [csdiy.wiki](https://csdiy.wiki/) full-catalog build.

![status](https://img.shields.io/badge/status-3%2F4%20complete-green)
![language](https://img.shields.io/badge/C%20%7C%20RISC--V%20%7C%20Logisim-informational)
![license](https://img.shields.io/badge/license-MIT-blue)

## Overview

CS61C ("Great Ideas in Computer Architecture") teaches how programs run on real
hardware: C and memory, RISC-V assembly and calling conventions, digital logic
and CPU design, and performance engineering with SIMD and threads. This repo
implements the course's four projects from the official starter code. Projects are
grounded on the current [cs61c.org](https://cs61c.org/) **Summer 2026** offering;
where a Su26 starter was not yet published (proj3, proj4), the most recent stable
semester's starter is used (Spring 2026 for the CPU, Fall 2025 for the matrix
project) and noted below.

## Results (measured on this machine — Windows 11 host, WSL2 Ubuntu, 16 logical CPUs)

| Project | What it is | Result (measured) |
|---|---|---|
| **proj1 · snek** | Snake game in C | unit tests + custom tests pass; **22/22** integration tests pass; **valgrind: 0 leaks, 0 errors** |
| **proj2 · CS61Classify** | Neural-net digit classifier in RISC-V asm | **46/46** unit tests (Venus); **9/9** coverage tests, 100% line coverage; 3/3 real classifications byte-identical to reference |
| **proj3 · CS61CPU** | RISC-V CPU in Logisim-Evolution | **ALU complete: 6/6 unit tests PASS headlessly** (all 13 ops incl. mul/mulh/mulhu, verified via `logisim -tty`); RegFile + full pipelined datapath are a documented partial (see `proj3-cpu/STATUS.md`, evidence in `proj3-cpu/results/`) |
| **proj4 · 61kaChow** | Matrix convolution, SIMD + OpenMP | correctness **7/7** vs NumPy reference (optimized == naive byte-for-byte); **~4.9× SIMD-only**, **~14× SIMD+OpenMP** speedup (best of 3, 16 threads; exact figure is load-dependent — see `proj4-kachow/results/speedup.txt`) |

Real captured outputs live in each project's `results/` directory.

## Implemented assignments

- [x] **proj1 — snek** (`proj1-snek/`): full snake game in C. `game.c` (board
  creation/teardown, printing, the `next_square`/`update_head`/`update_tail`/
  `update_game` step logic, dynamic non-rectangular board loading via
  `read_line`/`load_board`, and multi-snake discovery via `find_head`/
  `initialize_snakes`), the `snake.c` driver, and custom unit tests.
- [x] **proj2 — CS61Classify** (`proj2-classify/`): a two-layer ReLU network
  digit classifier in **RISC-V assembly**. Implements `abs`, `relu`, `argmax`,
  `dot`, `matmul`, `read_matrix`, `write_matrix`, and the top-level `classify`
  (read m0/m1/input → `matmul` → `relu` → `matmul` → write → `argmax`), plus the
  four coverage tests.
- [~] **proj3 — CS61CPU** (`proj3-cpu/`): the **ALU is fully implemented and
  passes all 6 unit tests headlessly** (`cpu/alu.circ` — add/sll/slt/xor/srl/or/
  and/mul/mulh/mulhu/sub/sra/bsel, built from Logisim components wired entirely by
  coordinate-free tunnels; evidence in `proj3-cpu/results/alu_tests.txt`). The
  register file and the pipelined CPU datapath remain the official starter — a
  documented partial. See `proj3-cpu/STATUS.md`.
- [x] **proj4 — 61kaChow** (`proj4-kachow/`): 2-D matrix convolution. A scalar
  `compute_naive.c` reference and an `compute_optimized.c` using **AVX2** 8-wide
  int32 intrinsics + **OpenMP**, plus the MPI compute variant.

## Project structure

```
cs61c/
├── proj1-snek/        C snake game        (src/, tests/, results/)
├── proj2-classify/    RISC-V classifier   (src/*.s, coverage-src/, tests/, results/)
├── proj3-cpu/         Logisim CPU starter (cpu/*.circ, harnesses/, tests/, STATUS.md)
├── proj4-kachow/      SIMD/OpenMP conv    (src/*.c, results/)
├── LICENSE            MIT (our code only)
└── README.md
```

## How to run

Toolchains: `gcc`/`make`/`valgrind` (WSL2 Ubuntu used for the C parts), `java`
(JDK 21, for Venus and Logisim), Python 3.11.

```bash
# proj1 — snek (C): unit, custom, integration, and valgrind tests
cd proj1-snek
make unit-tests && ./unit-tests
make custom-tests && ./custom-tests
make run-integration-tests
make valgrind-test-free-game

# proj2 — CS61Classify (RISC-V via Venus)
cd proj2-classify
bash tools/download_tools.sh venus       # fetches tools/venus.jar (git-ignored)
python unittests.py -v --               # 46 tests
python studenttests.py --               # coverage tests
# real end-to-end classification:
java -jar tools/venus.jar src/main.s --immutableText --maxsteps -1 -- \
  tests/classify-1/m0.bin tests/classify-1/m1.bin tests/classify-1/input.bin out.bin

# proj4 — 61kaChow (SIMD + OpenMP)
cd proj4-kachow
make convolve_naive_naive     COORDINATOR=naive COMPUTE=naive
make convolve_naive_optimized COORDINATOR=naive COMPUTE=optimized
# each binary takes an input.txt task list (see results/ for the verification harness)

# proj3 — CS61CPU (needs the Logisim GUI to build the circuits)
cd proj3-cpu
bash tools/download_tools.sh              # fetches logisim-evolution.jar + venus.jar
bash test.sh part_a                       # ALU, RegFile, addi  (once circuits are built)
bash test.sh part_b                       # full datapath + pipelined
```

## Verification

- **proj1**: the course's own `make unit-tests`, `make custom-tests`,
  `make run-integration-tests` (21 board diffs + a nonexistent-input-file check),
  and `make valgrind-test-free-game`. See `proj1-snek/results/`.
- **proj2**: the course's `unittests.py` (46 tests) and `studenttests.py`
  coverage suite, run through the **Venus** RISC-V simulator with
  `--callingConvention` enabled. Plus three real end-to-end runs of `main.s`
  whose `output.bin` is **byte-identical** to the provided `reference.bin`. See
  `proj2-classify/results/`.
- **proj4**: outputs compared against an independent NumPy convolution reference
  across 7 shapes (including non-multiple-of-8 kernels that exercise the SIMD
  tail path); the optimized output is byte-for-byte identical to the naive one.
  Speedup measured (best of 3) by timing the same workload — 4× (400×400 *
  100×100) + 2× (500×500 * 150×150) — under the naive scalar build, the AVX2
  build pinned to one thread, and the AVX2+OpenMP build on all 16 logical CPUs.
  Absolute times/ratios vary with host load; the committed run measured ~4.9×
  (SIMD-only) and ~14× (SIMD+OpenMP). See `proj4-kachow/results/`.
- **proj3**: the ALU (`cpu/alu.circ`) is verified with the course's own harness —
  `bash test.sh test_alu` runs each test circuit through `logisim-evolution.jar
  -tty table,binary,csv` and diffs against the staff reference: **6/6 PASS**,
  including `alu-all` (every ALUSel op) and `alu-mult` (mul/mulh/mulhu). Captured
  in `proj3-cpu/results/alu_tests.txt`. RegFile and the full pipelined CPU are an
  honest partial (`STATUS.md`).

## Tech stack

C (C99), RISC-V assembly (RV32IM), x86 AVX2/FMA SIMD intrinsics, OpenMP,
Logisim-Evolution, the Venus RISC-V simulator, GNU Make, Valgrind, Python
(NumPy) for verification harnesses.

## Key ideas / what I learned

- **Manual memory management & dynamic structures in C** — growable board rows and
  a snake array validated leak-free under Valgrind.
- **RISC-V calling conventions** — every classifier function preserves saved
  registers and stack discipline (Venus enforces this with `--callingConvention`).
- **Composing a neural net from primitives** — `matmul`/`relu`/`argmax` chained
  into a real digit classifier with byte-exact outputs.
- **Data-level + thread-level parallelism** — AVX2 8-wide int32 MAC with a scalar
  tail, kernel pre-flipping, and OpenMP `collapse(2)` over the output grid, for a
  ~9× end-to-end speedup that still matches the scalar reference exactly.
- **Digital-logic CPU design** — reverse-engineering the ALU operation set from
  reference test vectors (see `proj3-cpu/STATUS.md`).

## Credits & license

Based on the projects of **UC Berkeley CS61C — Great Ideas in Computer
Architecture**. Starter code and specifications belong to the CS61C staff
([cs61c.org](https://cs61c.org/), [github.com/61c-teach](https://github.com/61c-teach)).
This repository is an independent educational reimplementation; all course
materials belong to their original authors. Original code here is released under
the [MIT License](LICENSE).
