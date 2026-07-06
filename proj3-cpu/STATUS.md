# CS61CPU (proj3) — Status: ALU complete & verified; RegFile + full CPU are a documented partial

This directory contains the **official CS61CPU starter** (from `61c-teach/sp26-proj3-starter`),
plus a **fully implemented, headlessly-verified ALU** (`cpu/alu.circ`) built entirely by
coordinate-free Logisim-Evolution XML authoring. The register file and the pipelined CPU
datapath remain starter circuits — an honest, documented partial per the build's quality bar
("never pretend"), now much smaller than before.

## What is DONE and verified (real evidence in `results/alu_tests.txt`)

**`cpu/alu.circ` — the complete RISC-V ALU — passes all 6 unit tests headlessly (6/6):**

```
$ bash test.sh test_alu
PASS: tests/unit-alu/alu-add.circ
PASS: tests/unit-alu/alu-all.circ          <- comprehensive: exercises every ALUSel op
PASS: tests/unit-alu/alu-logic.circ
PASS: tests/unit-alu/alu-mult.circ
PASS: tests/unit-alu/alu-shift.circ
PASS: tests/unit-alu/alu-slt-sub-bsel.circ
Passed 6/6 tests
```

Every one of the 13 ALU operations is implemented and correct, selected by the 4-bit `ALUSel`:

| ALUSel | Op   | how it is built | ALUSel | Op    | how it is built |
|--------|------|-----------------|--------|-------|-----------------|
| `0000` | add  | `Adder`         | `1000` | mul (low 32)  | `Multiplier` (32b) |
| `0001` | sll  | `Shifter shift=ll` | `1001` | mulh (signed) | 64b `Multiplier` of sign-extended A,B → hi word |
| `0010` | slt (signed) | `Comparator mode=twosComplement`, LT bit zero-extended | `1011` | mulhu (unsigned) | 64b `Multiplier` of zero-extended A,B → hi word |
| `0100` | xor  | `XOR Gate`      | `1100` | sub   | `Subtractor` |
| `0101` | srl  | `Shifter shift=lr` | `1101` | sra   | `Shifter shift=ar` |
| `0110` | or   | `OR Gate`       | `1111` | bsel (= B) | tunnel alias |
| `0111` | and  | `AND Gate`      |        |       | |

The 13 operation results feed a **16:1 selection tree of 2:1 multiplexers** (4 levels,
15 muxes) driven by the four bits of `ALUSel` (extracted with a `Splitter`). Sign/zero
extension for the high-multiplies is built from `Splitter`s + a 2:1 mux that produces the
32-bit sign word (`0xFFFFFFFF`/`0x0`) from bit 31. `alu-all.ref` was independently decoded
to confirm this exact `ALUSel → operation` mapping before wiring.

### How the ALU was authored without a GUI (the technique)

Logisim-Evolution connects components where a net endpoint (wire / tunnel) lands **exactly**
on a component port pixel. Tunnels connect purely by **label**, so if you know a component's
port offsets relative to its `loc`, you can wire it blind. I recovered each component's port
geometry empirically by generating tiny probe circuits and reading `java -jar logisim -t table`,
then hard-coded the verified offsets. The verified offsets (component `loc` = `(x,y)`):

- **Adder / Subtractor / Multiplier (lib Arithmetic):** inputs `(-40,-10)` & `(-40,+10)`, output `(0,0)`.
- **AND/OR gate (`size=30`):** inputs `(-30,-10)` & `(-30,+10)`, output `(0,0)`.
- **XOR gate (`size=30`):** inputs `(-40,-10)` & `(-40,+10)`, output `(0,0)` (wider than AND/OR).
- **Shifter:** data `(-40,-10)`, distance (5-bit) `(-40,+10)`, output `(0,0)`; codes `ll`/`lr`/`ar`.
- **Comparator (`mode=twosComplement`):** A `(-40,-10)`, B `(-40,+10)`, signed-LT output `(0,+10)`.
- **2:1 Multiplexer (`select=1`):** d0 `(-30,-10)`, d1 `(-30,+10)`, sel `(-20,+20)`, output `(0,0)`.
- **Splitter (`facing=west`):** combined port at `loc`; group *k* at `(-20, +10 + 10·k)`
  (bidirectional — same geometry splits a bus or combines groups back into one).

## What remains (the documented partial)

- **`cpu/regfile.circ`** — needs 32 `Register`s, a 5→32 write-enable decoder, `x0` hard-wired
  to 0, and two 32:1 read multiplexers. This is large **sequential** logic (the harness steps
  the clock), not attempted here to a verified standard.
- **`cpu/cpu.circ` + the other datapath circuits** (control-logic, imm-gen, branch-comp,
  partial-load/store) and the **2-stage pipelined** variant — the full processor. Not implemented.

These are achievable with the same tunnel-authoring technique now that the geometry model is
solved, but each is a substantial build (esp. the clocked regfile and the pipelined datapath);
they are left for a GUI session.

## How to reproduce / finish

```bash
bash test.sh test_alu     # ALU: 6/6 PASS (verified here)
bash test.sh part_a       # ALU + RegFile + addi  (RegFile/addi still starter)
bash test.sh part_b       # full datapath + pipelined (--pipelined)
```

`logisim-evolution.jar` (14 MB) and `venus.jar` are **git-ignored**; fetch with
`bash tools/download_tools.sh`.
