#!/usr/bin/env python3
"""Generate build_soc/code.mem and build_soc/soc_test.defines for mkTbSoc.

Program: LOAD ifmap, LOAD weights, GEMM (1x1 conv), ALU (add), STORE.
Expected output (computed here) is placed in memory at EXP; the testbench compares OUT with EXP.
Memory map (must match src/Soc.bsv): base 0x00800000, 16 bytes per line.
"""
import argparse
import os
import random

MEM_BASE = 0x00800000
IBUF_START = 0x01000000
WBUF_START = 0x02000000
OBUF1_START = 0x03000000

PROG = 0x00800000
INP = 0x00810000
WGT = 0x00820000
OUT = 0x00830000
EXP = 0x00840000
ZERO = 0x00850000

OP_LOAD, OP_STORE, OP_GEMM, OP_ALU = 8, 9, 10, 11
ALU_ADD = 2
SENTINEL = int("DEADBEEF" * 4, 16)

ROWS = COLS = 16


def pack(fields):
    """fields: list of (value, width), MSB first."""
    v = 0
    for val, w in fields:
        assert 0 <= val < (1 << w), (val, w)
        v = (v << w) | val
    return v


def instr(opcode, flags, params):
    return (opcode << 124) | (flags << 120) | params


def mem_params(dram, sram, x, y, z, zs, ys, bitwidth):
    return pack([(dram, 32), (sram, 26), (x, 8), (y, 8), (z, 8), (zs, 8), (ys, 8),
                 (0, 1), (bitwidth, 1), (0, 20)])


def gemm_params(h, w, preload):
    return pack([(0, 15), (0, 15), (0, 15), (h, 8), (w, 8), (ROWS, 8), (COLS, 8),
                 (1, 4), (1, 4), (0, 4), (0, 4), (0, 4), (0, 4), (preload, 1), (0, 18)])


def alu_params(op, oh, ow, wh, ww, s_ow, s_r, s_s, active):
    return pack([(op, 2), (0, 15), (0, 15), (oh, 8), (ow, 8), (wh, 4), (ww, 4),
                 (s_ow, 8), (s_r, 8), (s_s, 8), (active, 8), (0, 1), (0, 8), (0, 23)])


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--pixels", type=int, default=2, help="ifmap pixels (1x1 conv); >2 currently stalls the array")
    ap.add_argument("--preload", type=int, default=0, help="GEMM preload_output flag (1 also loads zeros into OBUF)")
    ap.add_argument("--seed", type=int, default=1)
    ap.add_argument("--maxval", type=int, default=7)
    ap.add_argument("--out", default="build_soc/code.mem")
    a = ap.parse_args()
    n = a.pixels
    rnd = random.Random(a.seed)

    inp = [[rnd.randint(0, a.maxval) for _ in range(ROWS)] for _ in range(n)]
    wgt = [[rnd.randint(0, a.maxval) for _ in range(COLS)] for _ in range(ROWS)]
    out = [[sum(inp[p][k] * wgt[k][c] for k in range(ROWS)) for c in range(COLS)] for p in range(n)]

    lines = {}

    def put(addr, val):
        assert (addr - MEM_BASE) % 16 == 0
        lines[(addr - MEM_BASE) // 16] = val

    prog = [instr(OP_LOAD, 0, mem_params(INP, IBUF_START, 1, n, ROWS, 16, 16, 1))]
    if a.preload:
        prog.append(instr(OP_LOAD, 0, mem_params(ZERO, OBUF1_START, 1, n, COLS, 16, 16, 0)))
    prog += [
        instr(OP_LOAD, 1, mem_params(WGT, WBUF_START, 1, ROWS, COLS, 16, 16, 1)),
        instr(OP_GEMM, 9, gemm_params(1, n, a.preload)),
        instr(OP_ALU, 9, alu_params(ALU_ADD, 1, n, 1, 1, n, 1, 1, COLS)),
        instr(OP_STORE, 8, mem_params(OUT, OBUF1_START, 1, n, COLS, 16, 16, 0)),
    ]
    for i, v in enumerate(prog):
        put(PROG + 16 * i, v)

    # Bank j <- byte j of the line, MSB first.
    for p in range(n):
        put(INP + 16 * p, int.from_bytes(bytes(inp[p]), "big"))
    for k in range(ROWS):
        put(WGT + 16 * k, int.from_bytes(bytes(wgt[k]), "big"))

    # Store packs bank j into bits [32j+31:32j] of each 128-bit beat (4 beats per pixel).
    for p in range(n):
        for b in range(4):
            beat = sum(out[p][4 * b + j] << (32 * j) for j in range(4))
            put(EXP + 16 * (4 * p + b), beat)
            put(OUT + 16 * (4 * p + b), SENTINEL)
            put(ZERO + 16 * (4 * p + b), 0)

    last = max(lines)
    os.makedirs(os.path.dirname(a.out) or ".", exist_ok=True)
    with open(a.out, "w") as f:
        for i in range(last + 1):
            f.write("%032x\n" % lines.get(i, 0))
    with open(os.path.join(os.path.dirname(a.out) or ".", "soc_test.defines"), "w") as f:
        f.write("`define NUM_INS %d\n`define OUT_BEATS %d\n" % (len(prog), 4 * n))
    print("wrote %s: %d instructions, %d pixels, %d output beats" % (a.out, len(prog), n, 4 * n))


if __name__ == "__main__":
    main()
