# Change log: original SHAKTIMAAN -> SHAKTIMAAN_V2

Three checkpoints (tags): `v1-original` -> `v2-rtl-generation` -> `v3-soc-sim`.
Facts below come from the repository state, build logs and simulation runs; statements about *why* you made the
v2 edits are marked "inferred" because they were made before this documentation was written.

---

## Part A: v1-original -> v2-rtl-generation (edits made by the repo owner before the SoC work)

Goal: get the project through a Bluespec compiler on Ubuntu 26.04 and produce the RTL.

| File | Change | Why |
|---|---|---|
| (toolchain) | Use **BSC 2021.12.1** instead of 2026.07.1 | With 2026.07.1, `make generate_verilog` finishes the first modules, then fails during code generation of `mkshaktimaan` with `Internal Bluespec Compiler Error ... APath.aPaths': nodes not in graph` (kept in `error_bsc.txt`). 2021.12.1 generates all 10 modules. |
| `Makefile` (`compile` target) | Added `-no-aggressive-conditions -no-sched-conditions` to the Bluesim `bsc` command | Inferred: needed to get the Bluesim compile of the accelerator through. Does not affect `generate_verilog`. |
| `src/Soc.bsv` | Added the line `Ifc_accelerator systolic <- mk_accelerator;` in place of a blank line, leaving the old parameterised `Ifc_accelerator#(...)` line | Inferred: first step of adapting the SoC top to the current non-parameterised `Ifc_accelerator`. Left incomplete, so `Soc.bsv` **does not compile at v2** (two `systolic` declarations). It is not part of `generate_verilog`, so RTL generation is unaffected. |
| `src/Smoke.bsv` (new) | `mkSmoke`: instantiates the accelerator, ties all AXI inputs idle for 20 cycles | Quick elaboration/simulation check of the accelerator top. |
| `verilog/*.v` (new in git) | Output of `make generate_verilog` with BSC 2021.12.1 | The RTL checkpoint. Regenerating at the v2 tree gives identical files (apart from the date header) - verified. |
| `common_bsv/`, `fabrics/`, `common_verilog/` | Vendored (no `.git`), see `docs/DEPENDENCIES.md` | Needed for BSV compilation; unmodified upstream snapshots. |
| `BASELINE_VER_COMMIT`, `error_bsc.txt`, `log_compilation.txt` | Notes and logs | Record of the upstream commit and of the BSC attempts. |
| `.gitignore` | Stopped ignoring `verilog/` and the three dependency folders | So they can be committed. |

Not committed: `build-bsc2026-fresh/`, `verilog-bsc2026-fresh/` (artifacts of the failed 2026.07.1 attempt).

The RTL sources (`src/**`, except `Soc.bsv`/`Smoke.bsv`) are **identical to upstream at v2**, so the generated RTL at v2 is the
original architecture's RTL.

---

## Part B: v2-rtl-generation -> v3-soc-sim

Goal: a working, self-checking SoC simulation (accelerator + AXI fabric + memory), so the baseline can be
measured. Obtaining it required fixing the testbench *and* three real bugs in the accelerator RTL.

### B.1 `src/Soc.bsv` (SoC testbench `mkTbSoc`)

| Change | Reason |
|---|---|
| Removed stale `Ifc_accelerator#(ADDR_WIDTH,26,BUS_WIDTH,32768,...)` declaration | The interface is no longer parameterised; two `systolic` declarations did not compile. |
| Config write: `awlen: 16 -> 0`, `awsize: 0 -> 4`, `wstrb: 'b1 -> '1` | The write was announced as a 17-beat burst but only one data beat was sent; size 0 meant 1 byte; strobe only covered byte 0. The accelerator's config register takes a single 16-byte beat. |
| `ADDR_SPACE 25 -> 20` | Memory map is 1 MB (`0x00800000-0x008FFFFF`); 32 MB of BRAM only made Bluesim warn about an unfilled memory. |
| Instruction count `5` -> `` `NUM_INS `` from the generated `soc_test.defines` | Program length now comes from the generator. |
| Added timeout (200000 cycles) | The original testbench could hang forever. |
| Added CPU-master polling and comparison state machine (`WaitCfg, PollWait, PollRsp, CmpReqA/B, CmpRspA/B, Report`) | There was no completion signal and no result check. The CPU reads the last output beat until it is no longer the sentinel, then compares all output beats with the expected beats stored in memory; prints `RESULT: PASS/FAIL`, error count and the cycle, exits 0/1. |
| `rl_drain_wr_resp` | Pops the config write response so the master write-response FIFO never fills. |

### B.2 `Makefile`

| Change | Reason |
|---|---|
| New variables `SOC_BUILD`, `BSC_LIBS`, `SOC_INC`, `SOC_ARGS` | Separate output dir `build_soc/`; search path without the non-existent `%/Prelude` and `%/Libraries/BlueNoC` directories and the duplicated `src/` (they caused bsc warnings S0091/S0073 with BSC 2021). `SOC_INC` also contains `build_soc` so `` `include "soc_test.defines" `` is found. |
| New targets `soc_mem`, `soc_compile`, `soc_link`, `soc_run` | The default targets build the accelerator `mkshaktimaan`, not the SoC testbench `mkTbSoc`. `soc_compile` depends on `soc_mem` and deletes `Soc.bo`/`mkTbSoc.ba` so changed generated defines are always picked up. |

Existing targets are unchanged.

### B.3 `software/gen_code_mem.py` (new)

Generates `build_soc/code.mem` and `build_soc/soc_test.defines`. The upstream `software/conv_relu.c` could not be
used: wrong config address (`0xB0000000` vs `0x00900000`), host pointers as DRAM addresses, 16-bit data vs 8-bit
`INWIDTH`, a 16M-line output, and overlapping data regions; running its 5 instructions ended in a hang.
The generator:
- packs instructions exactly per `isa.bsv` (checked: it reproduces the original sample LOAD instruction bit for bit);
- places program at `0x00800000`, input at `0x00810000`, weights `0x00820000`, output `0x00830000`, expected `0x00840000`, zeros `0x00850000`;
- computes the expected result in Python (`out[p][c] = sum_k in[p][k]*w[k][c]`) and writes it in the word order the
  STORE unit produces;
- options: `--pixels N`, `--preload 0|1` (adds a LOAD of zeros into OBUF and sets GEMM `preload_output`), `--seed`, `--maxval`.

### B.4 Accelerator RTL fixes (the real architecture bugs)

**Symptom (measured at v2 RTL):** with the testbench fixed, GEMM with more than 2 pixels never finished. Column 0
produced all outputs but columns 1-15 only 2 each, so the output counter never reached zero and the store never ran.
Instrumentation showed e.g. 151 inputs entering the top PE row, 137 accumulations in it, and only 46 outputs
leaving the bottom row (16 + 15x2).

**Root cause 1 - no back-pressure inside the PE array.** A PE forwarded its input to the east neighbour through a
`Wire` that is valid only in the cycle `get_acc` fires. If the east PE's input FIFO (depth 2) was full, the value was
silently dropped, so downstream columns lost pixels and starved. The array only worked when every FIFO happened
never to fill (at most 2 pixels).

**Root cause 2 - zero-injection and request generation were not elastic.** One shared counter (driven only by column
0) decided how many zeros all 16 columns received, and the zeros/addresses were injected without skew or
back-pressure. Columns could receive too few or too many zeros, and address requests were dropped whenever a BRAM or
FIFO was busy.

**Root cause 3 - swapped buffer select.** In `accelerator.bsv` the request rule selects OBUF1 when the index MSB is 0,
but the response rules were wired the other way round (`obuf1` rule enabled for OBUF2 requests), so
accumulation (`preload_output=1`) never received data.

Changes:

| File | Change |
|---|---|
| `src/compute_module/intMul_WS.bsv` (PE) | The east-forward `Wire` `wr_west` is replaced by a 2-entry FIFO `ff_east`. `get_acc` now enqueues into it, so it blocks (back-pressure) instead of dropping; `subifc_get_inp` dequeues it. Interface unchanged. |
| `src/compute_module/systolic.bsv` | The last column has no east neighbour; a sink rule drains its `ff_east`. |
| `src/compute_module/compute_top.bsv` | (a) The shifted address registers/wires (`rg_inp_addr`, `rg_old_out_req`, ...) are replaced by per-row (`ff_inp_req`) and per-column (`ff_old_req`) request FIFOs; `rl_generate_inp_addr` stalls when any FIFO is full and runs only while `rg_inp_triangle` is set (the 16-cycle flush with `rg_row_cntr` is no longer used). (b) `rg_zero_cntr` is one counter per column; inactive columns also receive zeros and are drained by `rl_drain_inactive_col`, so tiles with `active_cols < 16` do not deadlock. (c) The output counter `rg_new_out_cntr` is decremented by a separate rule (`rl_dec_new_out_cntr`, driven by a `PulseWire` from the last active column) so the 16 column output methods no longer conflict on one register. (d) `get_inp_addr` / `get_old_out_addr` are now `toGet(FIFO)`. |
| `src/accelerator.bsv` | Row inputs go through `ff_inp_is_zero[i]` (depth 4), which records, in request order, whether each response is zero padding or IBUF data; this replaces the one-cycle `DReg` `rg_inp_req_valid`, which lost zero responses under stalls. The two `rl_forward_old_output_from_obuf*_to_gemm` conditions are swapped to match the request rule (bug 3). |

Behavioural consequences:
- Each PE column adds one cycle of latency (FIFO stage); the array is now an elastic dataflow pipeline, so the
  per-row skew registers are no longer needed. The datapath (MAC) is unchanged and numerically identical.
- Throughput of the verified cases is as in README_V2.md section 5.
- `rg_row_cntr`, `rg_op_triangle`, `rg_valid_row` still exist but have no effect any more.
- Remaining known limits are listed in README_V2.md section 5 (255 / 128 pixel limits are ISA-encoding limits, not new).

### B.5 `verilog/*.v`

Regenerated from the patched sources with `make generate_verilog` (BSC 2021.12.1). Logic changed in `mkcompute`,
`mkmac_ws`, `mksystolic_ws` and `mkshaktimaan` (which contains the inlined accelerator top). The other six modules
(`mkfetchdecode`, `mkdepend_resolver`, `mkload`, `mkstore`, `mkonchip_buffers`, `mktensoralu`) differ from v2 only in
the generated date header. The port lists of the top-level `mkshaktimaan` (the AXI interfaces) and of `mkmac_ws` are
identical to v2.

### B.6 `.gitignore`

Added `build_soc/` (generated, regenerate with `make soc_run`).

### B.7 Experiments that did not fix the problem (reverted or not needed)

- Replacing the `rg_new_out_cntr` decrement by a `PulseWire` alone (removes rule conflicts between output columns):
  no change in the stall. It is kept only as part of the final patch because it removes a real scheduling conflict.
- Compiling with `-aggressive-conditions`: no change.
- Debug `$display` instrumentation used to find the lost inputs: removed.

---

## Part C: Verification performed

| Check | Result |
|---|---|
| v2 tree: `make generate_verilog` (to a temp dir) vs committed `verilog/` | Identical except date headers |
| v3 tree: `make generate_verilog` | Succeeds, 10 files |
| v3 tree: `make soc_run` and variants | PASS for 1, 2, 3, 16, 64, 100, 255 pixels; preload 1, 4, 16, 128 pixels (table in README_V2.md) |
| Preload with 200 pixels | Fails from pixel 128 on (buffer select by index MSB: ISA/design limit) |
| Bluesim of `mkSmoke` | Not rerun at v3 |

Anything not in this table has not been tested.
