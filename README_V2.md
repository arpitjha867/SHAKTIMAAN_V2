# SHAKTIMAAN_V2 - SHAKTIMAAN accelerator, buildable and simulatable baseline

This repo is a working fork of [iitm-sysdl/SHAKTIMAAN](https://github.com/iitm-sysdl/SHAKTIMAAN)
(upstream commit `d3e240c`, a 16x16 weight-stationary INT8 systolic-array accelerator written in
Bluespec). The upstream README is kept unchanged in [README.md](README.md). This file describes what was
changed, how to build and run it, and what it can and cannot run today.

Companion documents:
- [docs/CHANGES.md](docs/CHANGES.md) - every change to the original code, with the reason.
- [docs/DEPENDENCIES.md](docs/DEPENDENCIES.md) - the vendored SHAKTI libraries (`common_bsv`, `fabrics`, `common_verilog`).

> These documents live on `main` (v3). Checking out an older tag shows the older tree without them.

---

## 1. Checkpoints (3 commits, 3 tags)

| Tag | Commit | State | Use it when |
|---|---|---|---|
| `v1-original` | 1 | Untouched upstream code (`d3e240c`). Dependencies are **not** included (upstream fetches them with `manager.sh`). | You want the pristine reference. |
| `v2-rtl-generation` | 2 | Your edits before the SoC work: `make generate_verilog` succeeds with BSC 2021.12.1 and the generated RTL is committed in `verilog/`. Dependencies vendored. `src/Soc.bsv` does **not** compile here. | You want the original architecture and RTL, with a compiler that works. |
| `v3-soc-sim` (= `main`) | 3 | Adds a working SoC testbench with self-checking PASS/FAIL, a test generator, and RTL back-pressure fixes. Regenerated RTL in `verilog/`. | You want to simulate and measure. |

Jump between them:

```bash
git tag -l                                  # list checkpoints
git switch --detach v1-original             # look at / build the original
git switch --detach v2-rtl-generation       # original architecture + working RTL generation
git switch main                             # latest (v3-soc-sim)

git switch -c my-experiment v2-rtl-generation   # start a branch from a checkpoint
git diff --stat v1-original v2-rtl-generation   # what changed between checkpoints
git diff v2-rtl-generation v3-soc-sim -- src     # RTL/testbench changes only
```

After switching, remove stale build products before compiling (they are git-ignored and survive a switch):

```bash
rm -rf build build_soc bin
```

---

## 2. Environment used

| Item | Version |
|---|---|
| OS | Ubuntu 26.04.1 LTS, Linux 7.0.0, x86_64 |
| **Bluespec compiler** | **BSC 2021.12.1 (build fd50140)**, binary release for Ubuntu 20.04, installed at `/opt/tools/bsc/bsc-2021.12.1-ubuntu-20.04` |
| Rejected compiler | BSC 2026.07.1 (build 63665af1) - `make generate_verilog` ends with an *Internal Bluespec Compiler Error* (`APath.aPaths': nodes not in graph`) during code generation of `mkshaktimaan` (see `error_bsc.txt`). |
| C++ (for Bluesim) | g++ 13.4.0 |
| Python | 3.14.4 (only the standard library is used) |
| make | GNU make |

Not needed for the flows below: Verilator, GTKWave (only to view VCDs), Vivado (only the optional `make vivado_build`).

Every shell must use the 2021 compiler:

```bash
export PATH=/opt/tools/bsc/bsc-2021.12.1-ubuntu-20.04/bin:$PATH
bsc -v | head -1        # must print: Bluespec Compiler, version 2021.12.1 (build fd50140)
```

(`/opt/tools/bsc/latest` points to 2026.07.1 on the development machine - do not use it.)
`BLUESPECDIR` is not needed; the root `Makefile` uses `%/Libraries` from the compiler install.
`src/Makefile` is the old upstream flow and is not used.

---

## 3. Build and run

All commands are run from the repository root.

### 3.1 Generate Verilog (accelerator top `mkshaktimaan`)

```bash
make generate_verilog        # writes verilog/*.v, build/*.bo|*.ba
```

Result: 10 files in `verilog/` (`mkshaktimaan`, `mkfetchdecode`, `mkdepend_resolver`, `mkload`, `mkstore`,
`mkcompute`, `mksystolic_ws`, `mkmac_ws`, `mktensoralu`, `mkonchip_buffers`). Do **not** run plain `make`
(default target `full_clean compile link simulate`): `full_clean` deletes `verilog/` and `mk*`.

### 3.2 SoC simulation in Bluesim (accelerator + AXI4 fabric + memory model + checker)

```bash
make soc_run                                       # 2 pixels (default), prints RESULT: PASS
make soc_run SOC_ARGS="--pixels 64"                # 64 pixels
make soc_run SOC_ARGS="--pixels 255 --seed 7 --maxval 15"
make soc_run SOC_ARGS="--pixels 128 --preload 1"   # accumulate path (GEMM preload_output=1)
grep RESULT build_soc/run.log
```

`soc_run` chains `soc_mem -> soc_compile -> soc_link -> run`:

| Target | What it does |
|---|---|
| `soc_mem` | `python3 software/gen_code_mem.py` writes `build_soc/code.mem` (program, input, weights, expected output) and `build_soc/soc_test.defines` (`NUM_INS`, `OUT_BEATS`). |
| `soc_compile` | `bsc -sim` of `src/Soc.bsv`, top `mkTbSoc`, into `build_soc/`. |
| `soc_link` | Links the Bluesim executable `build_soc/tbsoc`. |
| `soc_run` | Runs `tbsoc -m 250000` in `build_soc/`; log in `build_soc/run.log`. |

Expected last line, for example:
`RESULT: PASS, beats=8, errors=0, result_seen_at_cycle=283` (exit code 0). A failure prints `MISMATCH`
lines or `TIMEOUT: result never appeared (FAIL)` (exit code 1).

Waveform: `cd build_soc && ./tbsoc -m 5000 -V out.vcd && gtkwave out.vcd`.

### 3.3 What `build_soc/` contains (git-ignored, fully regenerable)

`code.mem`, `soc_test.defines`, `*.bo` / `*.ba` (BSC objects), `*.cxx` / `*.h` / `*.o` (Bluesim C++),
`tbsoc`, `tbsoc.so` (simulator), `run.log`. To rebuild everything from scratch:

```bash
rm -rf build_soc && make soc_run
```

### 3.3b How the testbench decides PASS/FAIL

`mkTbSoc` (`src/Soc.bsv`) is a CPU-less SoC: the "CPU" is an AXI master (id 0) that writes the start PC and
instruction count to the accelerator config register, then polls the last output beat in memory (initialised
to `0xDEADBEEF...`). When it changes, the CPU reads every output beat and the expected beat (computed by
Python, stored in memory) and compares them. `result_seen_at_cycle` is the cycle of the first poll that saw
the result (poll interval 16 cycles, so +/-16 cycles accuracy). Timeout: 200000 cycles.

---

## 4. Architecture (as implemented)

```
                 +------------- mkTbSoc (simulation only) -------------+
   CPU master -> |  AXI4 fabric (4 masters x 2 slaves, 32b addr/128b)   | -> Memory slave 0 : BRAM 0x00800000-0x008FFFFF
   (testbench)   |                                                      | -> Slave 1 : accelerator config 0x00900000-0x009FFFFF
                 +--^-------^-------^------^---------------------------+
                    |       |       |      |
                  fetch    load    store   config
                  master   master  master  slave
              +-----+-------+-------+------+------------------ mkshaktimaan (accelerator) -----+
              | mkfetchdecode -> mkdepend_resolver --+--> mkload  -> IBUF / WBUF / OBUF1 / OBUF2 |
              |   (fetch 128b instr, decode)         +--> mkcompute (weight-stationary 16x16)   |
              |                                      +--> mktensoralu (add/max/min/shift)       |
              |                                      +--> mkstore  <- OBUF                      |
              +----------------------------------------------------------------------------------+
```

Source: `src/accelerator.bsv` (top `mk_accelerator`, wrapper `mkshaktimaan`), `src/frontend_module/`
(fetch/decode, dependency resolver), `src/load_module/`, `src/store_module/`, `src/compute_module/`
(`compute_top.bsv` = control, `systolic.bsv`/`intMul_WS.bsv` = array/PE), `src/tensor_alu_module/`,
`src/buffers_module/` (BRAM-based buffers). Parameters: `src/commons/systolic.defines`.

### 4.1 Parameters (`src/commons/systolic.defines`)

| Parameter | Value | Meaning |
|---|---|---|
| `NUMROWS` x `NUMCOLS` | 16 x 16 | PE array (rows = input channels, columns = output channels) |
| `INWIDTH` / `OUTWIDTH` | 8 / 32 | INT8 inputs and weights (sign-extended in the MAC), 32-bit accumulators |
| `IBUF` / `WBUF` / `OBUF` | 256 entries each; banks 16 / 16 / 16 | `OBUF` exists twice (`OBUF1`, `OBUF2`), 32-bit words |
| `AXI_DATAWIDTH` / `DRAM_ADDR_WIDTH` | 128 / 32 | 16 bytes per beat; 3 accelerator masters + 1 slave |
| Queues | fetch 8, instruction 8, params 8, dependency 4 | `FETCH_QUEUE_SIZE`, `INS_QUEUE_SIZE`, `PARAMS_QUEUE_SIZE`, `DEP_QUEUE_SIZE` |
| Buffer address map (on-chip, used in LOAD/STORE `sram_address`) | IBUF `0x01000000`, WBUF `0x02000000`, OBUF1 `0x03000000`, OBUF2 `0x03800000` | 26-bit SRAM address: bank = low 4 bits, index = next 8 bits |
| Config register | `0x00900000` | write: `data[31:0]` = start PC, `data[47:32]` = number of instructions |
| AXI master ids | CPU 0, fetch 1, load 2, store 3 | |

### 4.2 Instruction set (128 bits, 16-byte aligned in memory)

`[127:124]` opcode: `8` LOAD, `9` STORE, `10` GEMM, `11` ALU. `[123:120]` dependency flags (MSB first):
`pop_prev, push_prev, pop_next, push_next`. `[119:0]` parameters (field order MSB first, from `src/commons/isa.bsv`):

| Opcode | Fields (bits) |
|---|---|
| LOAD / STORE | `dram_address`(32) `sram_address`(26) `x_size`(8) `y_size`(8) `z_size`(8) `z_stride`(8) `y_stride`(8) `is_reset`(1) `bitwidth`(1) pad(20). `bitwidth=1`: 8-bit elements (IBUF/WBUF); `0`: 32-bit (OBUF). Strides are in elements. |
| GEMM | `input_address`(15) `output_address`(15) `weight_address`(15) `ofmap_height`(8) `ofmap_width`(8) `active_rows`(8) `active_cols`(8) `stride_h`(4) `stride_w`(4) `pad_left/right/top/bottom`(4 each) `preload_output`(1) pad(18) |
| ALU | `alu_opcode`(2: 0 max, 1 min, 2 add, 3 shift) `input_address`(15) `output_address`(15) `output_height`(8) `output_width`(8) `window_height`(4) `window_width`(4) `mem_stride_OW/R/S`(8 each) `num_active`(8) `use_immediate`(1) `immediate_value`(8) pad(23) |

Dependency queues (from `dependency_resolver.bsv`): LOAD `push_next` -> GEMM `pop_prev`; GEMM `push_prev` ->
LOAD `pop_next`; GEMM `push_next` -> ALU `pop_prev`; ALU `push_prev` -> GEMM `pop_next`; ALU `push_next` ->
STORE `pop_prev`; STORE `push_prev` -> ALU `pop_next`. Instructions of one kind execute in order. Test program
used here: LOAD ifmap (0), LOAD weights (1 = push_next), GEMM (9), ALU (9), STORE (8).

### 4.3 Dataflow notes

- Weight-stationary: weights are loaded per GEMM instruction (row `k` of the weight matrix = WBUF index
  `weight_address+k`, bank = output channel); then `ofmap_height x ofmap_width` input pixels (one IBUF index =
  one pixel, 16 channels over 16 banks) are streamed. `out[p][c] = sum_k in[p][k] * w[k][c]`. Verified bit-exact.
- A GEMM instruction handles one (r,s) kernel offset with up to 16 input and 16 output channels; larger
  convolutions need several GEMM instructions accumulated with `preload_output=1`.
- IBUF/WBUF LOAD: byte `j` of a beat (MSB first) goes to bank `j`. STORE packs bank `j` into bits
  `[32j+31:32j]` of the beat (word 0 in the least significant bits). LOAD into OBUF uses the MSB-first order, so
  a non-zero LOAD->STORE round trip through OBUF reorders the 4 words of a beat (read from the code, not tested).
- Where a result goes: GEMM writes OBUF1 or OBUF2 chosen by the MSB of `output_address` (index bit 7). The
  accumulate (preload) read selects the buffer per index MSB; hence preload tiles are limited to 128 pixels.

---

## 5. What the accelerator can run now (v3)

Verified in Bluesim against a Python golden model (INT8 inputs/weights, exact 32-bit sums):

| Test (`SOC_ARGS`) | Result | `result_seen_at_cycle` (+/-16) |
|---|---|---|
| `--pixels 1` | PASS | 257 |
| `--pixels 2` (default) | PASS | 283 |
| `--pixels 3` | PASS | 309 |
| `--pixels 16` | PASS | 736 |
| `--pixels 64` | PASS | 2292 |
| `--pixels 100 --seed 7 --maxval 15` | PASS | 3446 |
| `--pixels 255` | PASS | 8491 |
| `--pixels 4/16/128 --preload 1` | PASS | 391 / 925 / 5770 |

(Cycle counts cover the whole program: fetch, both loads, GEMM, ALU, store; values 0..7 or 0..15 only.)

Limits and not-yet-verified features:

- Tested shape: 1x1 convolution = dense GEMM with K=16, N=16 (one weight tile), M up to 255 pixels.
- `ofmap_height*ofmap_width` is an 8-bit product: **max 255 pixels per GEMM instruction**; with `preload_output=1`
  **max 128**.
- Not yet tested: 3x3 kernels with padding/stride, `pad_*` fields, `active_rows/cols < 16`, ALU ReLU/max-pool/shift,
  `use_immediate`, several tiles per program, double buffering, OBUF2, non-zero preload data, negative values,
  values larger than 15.
- Memory model is 1 MB with ideal BRAM timing (`tb/bram.bsv`); no DRAM latency/bandwidth model.
- Cycle counts are RTL-level (Bluesim); no frequency/area/power (needs synthesis: `make vivado_build`, Xilinx
  `xc7a100tcsg324-1` in the Makefile).

---

## 6. Can the original code run our workloads (ResNet-50, GCN on Cora)?

**Original (v1) / v2:** no.
- `src/Soc.bsv` does not compile (stale parameterised interface line) and has no program image, no checker.
- Even with a working testbench the original array **stalls after 2 pixels per column** (data is dropped inside
  the array, see CHANGES.md). The v2 RTL is identical to the original RTL, so it has the same flaw.

**v3:** the array no longer stalls and is bit-exact on the verified GEMM tiles above, but it still needs more
work before real workloads (no more changes to the array's dataflow are known to be required; the work is mostly
software/testbench):

1. A layer-to-instruction compiler (tiling, quantisation, DRAM layout, dependency flags, golden model) built on
   `software/gen_code_mem.py`.
2. Verify the untested ISA features listed in section 5 (3x3 conv + padding, ALU ops, accumulation across
   kernel offsets/channel tiles, multi-tile programs).
3. A larger memory map (`MemoryEnd`/`ADDR_SPACE` in `systolic.defines`/`Soc.bsv`; currently 1 MB) and a testbench that reads
   the program/result addresses from memory instead of compile-time constants.
4. A way to run many layers (Bluesim is slow): simulate layer by layer and extrapolate.
5. GCN/Cora: the feature transform `X*W` is a dense GEMM and fits. Sparse aggregation `A*H` has no sparse
   support in this ISA: run it as a dense GEMM on the (quantised) adjacency matrix or on the host.

---

## 7. Roofline: what to change in the baseline

Peak compute (INT8): `NUMROWS * NUMCOLS` MAC/cycle = **256 MAC/cycle = 512 ops/cycle** at 100 % utilisation;
peak GOPS = `512 * f_clk[GHz]`. `f_clk` is **not** available from simulation (needs synthesis/STA).
Peak bandwidth: `AXI_DATAWIDTH/8` = **16 bytes/cycle per AXI master**; the accelerator has separate fetch, load and
store masters (instruction fetch uses little data).
Operational intensity of a layer = MACs*2 / bytes moved through load+store; attainable ops/cycle =
`min(512, intensity * bytes/cycle of the memory you model)`.

Where each roofline input lives:

| Input | File / symbol | Notes |
|---|---|---|
| Array size (compute roof) | `src/commons/systolic.defines`: `NUMROWS`, `NUMCOLS` | `IBUF_BANKS`/`WBUF_BANKS` follow them; the provisos in `accelerator.bsv` require `IBUF_BANKS` and `WBUF_BANKS` to be multiples of `AXI_DATAWIDTH/INWIDTH` (16) and `OBUF_BANKS` a multiple of `AXI_DATAWIDTH/OUTWIDTH` (4). So the array can only change in steps of 16 unless the bus width or data width changes too. |
| Data widths | `INWIDTH`, `OUTWIDTH` | |
| Bus width (bandwidth roof) | `AXI_DATAWIDTH`; also `` `BUS_WIDTH `` in `src/Soc.bsv` | Both must match. Burst logic in `load_module.bsv` / `store_module.bsv` uses it. |
| Buffer capacity (tiling limits) | `IBUF_ENTRIES`, `WBUF_ENTRIES`, `OBUF_ENTRIES` | Also limited by `DIM_WIDTH1..3` field widths in the ISA. |
| ISA field limits | `DIM_WIDTH1` (8), `DIM_WIDTH2` (4), `DIM_WIDTH3` (15), `src/commons/isa.bsv` | |
| Memory size and map | `MemoryBase/End`, `SysBase/End`, `CONFIG_ADDR` (`systolic.defines`), `ADDR_SPACE` (`Soc.bsv`) | |
| Memory latency / bandwidth model | `tb/bram.bsv` (`mkbram_axi4`) | Ideal on-chip BRAM; replace or wrap it with a latency/bandwidth-limited DRAM model for realistic rooflines. |
| Fabric | `fabrics/axi4/AXI4_Fabric.bsv` | Crossbar arbitration between the masters. |
| Measurement points | `src/Soc.bsv` (cycle counter `rg_cycle`) | Add per-phase cycle counters (load, gemm, alu, store) here or in the modules. |

Because the pixel and preload limits (255/128) are ISA/encoding limits, a roofline over large layers must be built
from many instructions; the compiler in item 1 of section 6 is required.

---

## 8. Repository layout (additions in bold)

```
Makefile                 root build (generate_verilog, Bluesim compile; **soc_* targets**)
src/                     accelerator sources; **Soc.bsv = SoC testbench top (mkTbSoc)**; Smoke.bsv = idle smoke test
tb/                      memory model (bram.bsv) and old unit testbenches
software/                conv_relu.c (old, unusable as-is), **gen_code_mem.py (test generator)**
common_bsv/ fabrics/ common_verilog/   **vendored dependencies (docs/DEPENDENCIES.md)**
verilog/                 **generated RTL (BSC 2021.12.1), regenerated at v3**
docs/                    upstream docs + **CHANGES.md, DEPENDENCIES.md**
BASELINE_VER_COMMIT, error_bsc.txt, log_compilation.txt   notes/logs from getting BSC to compile (v2)
build/ build_soc/ bin/   git-ignored build output
```

## 9. Git identity

Commits are authored by `arpitjha867 <arpitjha867@gmail.com>`.
