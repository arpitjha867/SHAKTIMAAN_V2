# External dependencies (vendored snapshots)

SHAKTIMAAN does not contain these libraries itself. Upstream `manager.sh update_deps` clones them from
GitLab into the repo root. In this repo they are committed **as snapshots** (without their own `.git`
folders) so every checkpoint can be rebuilt without GitLab.

None of them has been modified: each snapshot is identical to the upstream commit listed below.

| Folder | Upstream | Commit | Used for |
|---|---|---|---|
| `common_bsv/` | https://gitlab.com/shaktiproject/common_bsv (branch `master`) | `42d7768ec81abf7f657ec8302a6ff5a0584ace22` | Shared BSV helpers: `Logger.bsv` (the `logLevel` macro), `device_common.bsv`, `TxRx.bsv`, `CustomFIFOs.bsv`, ... Imported by `tb/bram.bsv` and several modules. |
| `fabrics/` | https://gitlab.com/shaktiproject/uncore/fabrics (checkout `1.1.0`, detached) | `23b85ed13845afa08f8c6d2e7aa8db58b1f816c5` | AXI4 types, `AXI4_Fabric` (crossbar) and master/slave transactors: `fabrics/axi4/`, `fabrics/axi4lite/`, `fabrics/bridges/`. Used by the accelerator (AXI masters and slave) and by the SoC testbench. |
| `common_verilog/` | https://gitlab.com/shaktiproject/common_verilog (branch `master`) | `029a15059798d5400d0821934f2f36e192b92d01` | Verilog primitives (BRAM models, etc.). Needed only when simulating or synthesising the generated Verilog, not for BSV compilation or Bluesim. |

## How the build finds them

The root `Makefile` puts `./fabrics/axi4`, `./fabrics/bridges`, `./fabrics/axi4lite`, `./common_bsv` and `./tb`
on the BSC search path (`-p`). The folders therefore must sit at the repository root.

## Re-fetching the original versions

```bash
git clone https://gitlab.com/shaktiproject/common_bsv        && git -C common_bsv     checkout 42d7768ec81abf7f657ec8302a6ff5a0584ace22
git clone https://gitlab.com/shaktiproject/uncore/fabrics     && git -C fabrics        checkout 23b85ed13845afa08f8c6d2e7aa8db58b1f816c5
git clone https://gitlab.com/shaktiproject/common_verilog     && git -C common_verilog checkout 029a15059798d5400d0821934f2f36e192b92d01
```

`./manager.sh update_deps` follows moving branches (`master`, `1.1.0`) and may give different code than the
snapshots here; do not use it if you want a reproducible build. Never run `./manager.sh nuke`.

## Licences

Each folder keeps its own LICENSE / README from upstream (SHAKTI, IIT Madras).
