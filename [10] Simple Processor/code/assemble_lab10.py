#!/usr/bin/env python3
"""assembler for the stack processor"""
from pathlib import Path
import csv
import re

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "program" / "lab10_program.asm"
OUT_HEX = ROOT / "program" / "lab10_program.hex"
OUT_MIF = ROOT / "program" / "lab10_program.mif"
OUT_IHEX = ROOT / "program" / "lab10_program.ihex"
OUT_BIN = ROOT / "program" / "lab10_program.bin"
OUT_LIST = ROOT / "program" / "lab10_program.lst"
OUT_CSV = ROOT / "program" / "lab10_program.csv"
OUT_VH = ROOT / "rtl" / "lab10_program.vh"

OPCODES = {
    "PUSHC": 0x0,
    "PUSH":  0x1,
    "POP":   0x2,
    "JUMP":  0x3,
    "JZ":    0x4,
    "JS":    0x5,
    "ADD":   0x6,
    "SUB":   0x7,
    "SWAP":  0x8,
    "SHL":   0x9,
    "CMP":   0xA,
}
OPERAND_OPS = {"PUSHC", "PUSH", "POP"}


def parse_number(token: str, labels: dict) -> int:
    t = token.strip().upper()
    if t in labels:
        return labels[t]
    if re.fullmatch(r"[0-9A-F]{2}", t):
        return int(t, 16)
    if re.fullmatch(r"0X[0-9A-F]+", t):
        return int(t, 16)
    if re.fullmatch(r"[0-9]+", t):
        return int(t, 10)
    raise ValueError(f"Unknown operand: {token}")


def load_source():
    parsed = []
    for lineno, raw in enumerate(SRC.read_text(encoding="utf-8").splitlines(), 1):
        code = raw.split(";", 1)[0].strip()
        if not code:
            continue
        if code.endswith(":"):
            parsed.append((lineno, "LABEL", code[:-1].strip().upper(), None, raw.rstrip()))
            continue
        parts = code.replace(",", " ").split()
        op = parts[0].upper()
        if op not in OPCODES:
            raise ValueError(f"Line {lineno}: unsupported opcode {op}")
        operand = parts[1] if len(parts) > 1 else None
        if op in OPERAND_OPS and operand is None:
            raise ValueError(f"Line {lineno}: {op} requires an 8-bit operand")
        if op not in OPERAND_OPS and operand is not None:
            raise ValueError(f"Line {lineno}: {op} takes no operand")
        parsed.append((lineno, "INST", op, operand, raw.rstrip()))
    return parsed


def intel_hex_record(address: int, data: bytes) -> str:
    count = len(data)
    rec_type = 0
    fields = [count, (address >> 8) & 0xFF, address & 0xFF, rec_type] + list(data)
    checksum = (-sum(fields)) & 0xFF
    return ":" + "".join(f"{b:02X}" for b in fields + [checksum])


def main():
    parsed = load_source()
    labels = {}
    pc = 0

    for lineno, kind, op_or_label, operand, raw in parsed:
        if kind == "LABEL":
            if op_or_label in labels:
                raise ValueError(f"Line {lineno}: duplicate label {op_or_label}")
            labels[op_or_label] = pc
        else:
            pc += 2 if op_or_label in OPERAND_OPS else 1
            if pc > 0xF8:
                raise ValueError("Program overlaps memory-mapped I/O area starting at F8")

    memory = [0x00] * 256
    rows = []
    pc = 0
    for lineno, kind, op_or_label, operand, raw in parsed:
        if kind == "LABEL":
            continue
        op = op_or_label
        opcode_byte = OPCODES[op] << 4
        memory[pc] = opcode_byte
        start = pc
        pc += 1
        operand_value = None
        if op in OPERAND_OPS:
            operand_value = parse_number(operand, labels)
            if not 0 <= operand_value <= 0xFF:
                raise ValueError(f"Line {lineno}: operand out of range: {operand}")
            memory[pc] = operand_value
            pc += 1
        rows.append((start, opcode_byte, operand_value, op, operand or "", raw.strip()))

    OUT_HEX.write_text("\n".join(f"{b:02X}" for b in memory) + "\n", encoding="ascii")
    OUT_BIN.write_bytes(bytes(memory))

    with OUT_MIF.open("w", encoding="ascii") as f:
        f.write("WIDTH=8;\nDEPTH=256;\n\nADDRESS_RADIX=HEX;\nDATA_RADIX=HEX;\n\nCONTENT BEGIN\n")
        for addr, b in enumerate(memory):
            f.write(f"    {addr:02X} : {b:02X};\n")
        f.write("END;\n")

    with OUT_VH.open("w", encoding="ascii") as f:
        f.write("// program memory\n")
        for addr, b in enumerate(memory):
            f.write(f"memory[8'h{addr:02X}] = 8'h{b:02X};\n")

    lines = []
    for base in range(0, 256, 16):
        chunk = bytes(memory[base:base+16])
        lines.append(intel_hex_record(base, chunk))
    lines.append(":00000001FF")
    OUT_IHEX.write_text("\n".join(lines) + "\n", encoding="ascii")

    with OUT_LIST.open("w", encoding="utf-8") as f:
        f.write("machine code listing\n")
        f.write("opcode is in bits [7:4]\n\n")
        for start, opcode_byte, operand_value, op, operand_text, raw in rows:
            if operand_value is None:
                machine = f"{opcode_byte:02X}"
            else:
                machine = f"{opcode_byte:02X} {operand_value:02X}"
            f.write(f"{start:02X}  {machine:<5}  {op:<5} {operand_text:<10} ; {raw}\n")
        f.write("\nLabels:\n")
        for name, addr in sorted(labels.items(), key=lambda kv: kv[1]):
            f.write(f"{name:<12} = {addr:02X}\n")

    with OUT_CSV.open("w", newline="", encoding="utf-8-sig") as f:
        w = csv.writer(f)
        w.writerow(["address_hex", "machine_bytes", "instruction", "operand", "source"])
        for start, opcode_byte, operand_value, op, operand_text, raw in rows:
            machine = f"{opcode_byte:02X}" if operand_value is None else f"{opcode_byte:02X} {operand_value:02X}"
            w.writerow([f"{start:02X}", machine, op, operand_text, raw])

    print(f"program size = {pc} bytes")
    print("labels:")
    for name, addr in sorted(labels.items(), key=lambda kv: kv[1]):
        print(f"  {name:12s} 0x{addr:02X}")
    print("program files written")


if __name__ == "__main__":
    main()
