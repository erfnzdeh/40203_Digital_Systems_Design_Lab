#!/usr/bin/env python3
"""small program checker"""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
HEX = ROOT / "program" / "lab10_program.hex"


def load_memory():
    vals = [int(line.strip(), 16) for line in HEX.read_text().splitlines() if line.strip()]
    if len(vals) != 256:
        raise RuntimeError(f"wrong memory size: {len(vals)}")
    return vals


def run_case(x, max_steps=10000):
    mem = load_memory()
    ports = {0xF9: 0, 0xFA: 0, 0xFB: 0, 0xFC: 0}
    stack = []
    pc = 0
    s = 0
    z = 0
    steps = 0
    max_depth = 0
    halt_address = 0x99

    while steps < max_steps:
        if pc == halt_address and steps > 0:
            return {
                "display": ((ports[0xFA] & 0x0F) << 4) | (ports[0xF9] & 0x0F),
                "error": ports[0xFB] & 1,
                "done": ports[0xFC] & 1,
                "steps": steps,
                "max_stack_depth": max_depth,
            }

        inst = mem[pc]
        pc = (pc + 1) & 0xFF
        op = (inst >> 4) & 0x0F

        if op == 0x0:  # pushc
            stack.append(mem[pc]); pc = (pc + 1) & 0xFF
        elif op == 0x1:  # push
            addr = mem[pc]; pc = (pc + 1) & 0xFF
            if addr == 0xF8:
                stack.append(x)
            elif addr < 0xF8:
                stack.append(mem[addr])
            else:
                stack.append(0)
        elif op == 0x2:  # pop
            addr = mem[pc]; pc = (pc + 1) & 0xFF
            value = stack.pop()
            if addr in ports:
                ports[addr] = value
            elif addr < 0xF8:
                mem[addr] = value
        elif op == 0x3:  # jump
            pc = stack.pop()
        elif op == 0x4:  # jz
            target = stack.pop()
            if z:
                pc = target
        elif op == 0x5:  # js
            target = stack.pop()
            if s:
                pc = target
        elif op == 0x6:  # add
            a = stack.pop(); b = stack.pop()
            result = (b + a) & 0xFF
            stack.append(result)
            z = int(result == 0)
            s = (result >> 7) & 1
        elif op == 0x7:  # sub = B-A
            a = stack.pop(); b = stack.pop()
            result = (b - a) & 0xFF
            stack.append(result)
            z = int(result == 0)
            s = (result >> 7) & 1
        elif op == 0x8:  # swap
            stack[-1], stack[-2] = stack[-2], stack[-1]
        elif op == 0x9:  # shl
            stack[-1] = (stack[-1] << 1) & 0xFF
        elif op == 0xA:  # cmp
            a = stack[-1]; b = stack[-2]
            result = (b - a) & 0xFF
            z = int(result == 0)
            s = (result >> 7) & 1
        else:
            pass  # reserved

        max_depth = max(max_depth, len(stack))
        if len(stack) > 8:
            raise RuntimeError(f"stack overflow: x={x} pc={pc:02X}")
        steps += 1

    raise RuntimeError(f"timeout: x={x} pc={pc:02X}")


def expected(x):
    if x >= 128:
        return 0, 1
    if x < 32:
        y = 3*x + 5
    elif x < 64:
        y = 2*x + 20
    else:
        y = x - 40
    if y > 127:
        return 0, 1
    return y, 0


def main():
    mandatory = [0, 31, 32, 53, 54, 63, 64, 127, 128, 255]
    print("program check")
    for x in mandatory:
        result = run_case(x)
        exp_display, exp_error = expected(x)
        ok = (result["display"] == exp_display and result["error"] == exp_error and result["done"] == 1)
        print(f"X={x:3d} display={result['display']:02X} error={result['error']} done={result['done']} "
              f"depth={result['max_stack_depth']}  {'ok' if ok else 'error'}")
        if not ok:
            raise SystemExit(1)

    global_depth = 0
    for x in range(256):
        result = run_case(x)
        exp_display, exp_error = expected(x)
        if (result["display"], result["error"], result["done"]) != (exp_display, exp_error, 1):
            raise SystemExit(f"wrong result at x={x}")
        global_depth = max(global_depth, result["max_stack_depth"])

    print("\nall 256 inputs checked")
    print(f"max stack depth = {global_depth}")


if __name__ == "__main__":
    main()
