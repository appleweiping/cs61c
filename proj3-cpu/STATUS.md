# CS61CPU (proj3) — Status: documented partial

This directory contains the **official CS61CPU starter** (from `61c-teach/sp26-proj3-starter`)
imported unmodified, plus this status note. The CPU circuits themselves are **not
implemented** here. This is an honest, documented partial per the build's quality bar
("never pretend").

## Why this is a partial

CS61CPU is built entirely in **Logisim-Evolution** as `.circ` files. Logisim circuits are
XML documents in which every component and every wire is placed at exact pixel coordinates,
and connectivity depends on ports landing on precisely the right coordinates. The project is
normally completed **interactively in the Logisim GUI**, which this headless build
environment does not have.

I verified that the surrounding tooling works and that pure-XML authoring is *partially*
feasible, but could not get it to a fully verified-passing state:

- **The autograder harness runs headlessly and is fully usable.** `java -jar
  tools/logisim-evolution.jar -t table cpu/alu.circ` dumps a circuit's truth table, and
  `python tools/run_test.py tests/...` diffs a circuit's output against the reference. Both
  were confirmed working here (the starter ALU correctly reports `UUUUUUUU` for the
  unimplemented result).
- **Pure-XML editing can connect staff-placed components.** I confirmed that wiring the
  starter's staff-placed `Adder` output tunnel (`add0`) to `ALUResult` makes
  `tests/unit-alu/alu-add.circ` **PASS** — so a tunnel-based ALU is connectable in principle.
- **The blocker:** new components I place (especially the 16-input `Multiplexer` that selects
  the active ALU operation, and the `Shifter`/`Multiplier`/`Comparator` blocks) require exact
  port pixel-coordinates that Logisim-Evolution computes dynamically from component bounds,
  facing, and select-width. Without the GUI (which snaps wires to ports and shows
  connectivity), and after a wide empirical coordinate sweep (~100 candidate geometries dumped
  via `-t table`), I could not reliably land tunnels on the mux data/select ports. Authoring
  the full datapath (ALU + 32-register regfile + imm-gen + branch-comp + control-logic +
  partial-load/store + a 2-stage pipelined `cpu.circ`) blind to component geometry is not
  achievable to a verified standard here.

## What *was* produced (real, reusable analysis)

The ALU operation spec was fully reverse-engineered from the reference test vectors in
`tests/unit-alu/out/alu-all.ref`. `ALUSel` (4 bits) selects:

| ALUSel | Op    | ALUSel | Op            |
|--------|-------|--------|---------------|
| `0000` | add   | `1000` | mul (low 32)  |
| `0001` | sll   | `1001` | mulh (signed) |
| `0010` | slt (signed) | `1011` | mulhu (unsigned) |
| `0100` | xor   | `1100` | sub           |
| `0101` | srl   | `1101` | sra           |
| `0110` | or    | `1111` | bsel (= B)    |
| `0111` | and   |        |               |

This mapping was validated numerically against every distinct `ALUSel` row in the reference
(e.g. `0x00007fff + 0x00000001 = 0x00008000` for add; `0xf234567f << 9 = 0x68acfe00` for sll;
`mulhu(0xf435daa4, 0x72381add) = 0x6cf580c5`).

## How to finish it (in a GUI environment)

1. `bash tools/download_tools.sh` — fetches `logisim-evolution.jar` and `venus.jar`.
2. Open each `cpu/*.circ` in Logisim-Evolution and build the datapath per the ALU table above
   and the RISC-V RV32 datapath.
3. Verify: `bash test.sh part_a` (ALU, RegFile, addi) and `bash test.sh part_b`
   (branch-comp, imm-gen, partial-load/store, integration + pipelined with `--pipelined`).

## Tools

`logisim-evolution.jar` (14 MB) and `venus.jar` (11 MB) are **git-ignored**; download them with
`bash tools/download_tools.sh`.
