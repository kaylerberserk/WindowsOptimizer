#!/usr/bin/env python3
import re
import sys
from pathlib import Path

LABEL = re.compile(r"^:([A-Za-z0-9_.\-]+)\s*$")
COMMENT = re.compile(r"^\s*@?(rem\b|::)", re.I)
TEXT = re.compile(r"^\s*@?(echo|set)\b", re.I)
JUMP = re.compile(r"\b(goto|call)\s*(:?)([^\s&|()<>^\"]+)", re.I)
TERMINAL = re.compile(r"^\s*@?(goto\s*:?\S+|exit(\s+/b)?(\s+\S+)?)\s*$", re.I)
BUILTIN = {"EOF"}


def check_format(data):
    for i, byte in enumerate(data):
        if byte == 0 or byte > 127:
            return 44, f"non-ASCII/NUL byte 0x{byte:02x} at offset {i}"
        if byte == 10 and (i == 0 or data[i - 1] != 13):
            return 42, f"bare LF at offset {i}"
        if byte == 13 and (i + 1 >= len(data) or data[i + 1] != 10):
            return 42, f"bare CR at offset {i}"
    return 0, "7-bit ASCII, every line CRLF"


def check_labels(lines):
    labels, problems, referenced = {}, [], set()
    for n, line in enumerate(lines, 1):
        m = LABEL.match(line)
        if m:
            name = m.group(1).upper()
            if name in labels:
                problems.append(f"L{n}: duplicate label :{m.group(1)} (first L{labels[name]})")
            labels.setdefault(name, n)
    for n, line in enumerate(lines, 1):
        if COMMENT.match(line) or TEXT.match(line) or LABEL.match(line):
            continue
        for verb, colon, target in JUMP.findall(line):
            if verb.lower() == "call" and not colon:
                continue
            if "%" in target or "!" in target:
                problems.append(f"L{n}: dynamic {verb.lower()} target {target} cannot be checked")
                continue
            name = target.upper()
            if name in BUILTIN:
                continue
            referenced.add(name)
            if name not in labels:
                problems.append(f"L{n}: {verb.lower()} target :{target} does not exist")
    previous = None
    for n, line in enumerate(lines, 1):
        m = LABEL.match(line)
        if m:
            name = m.group(1).upper()
            falls_in = previous is not None and not TERMINAL.match(previous)
            if name not in referenced and not falls_in:
                problems.append(f"L{n}: label :{m.group(1)} is unreachable (no goto/call, no fall-through)")
            continue
        if line.strip() and not COMMENT.match(line):
            previous = line
    return len(labels), problems


def main(path):
    try:
        data = Path(path).read_bytes()
    except OSError as error:
        print(f"[FAIL] cannot read {path}: {error}")
        return 43
    code, message = check_format(data)
    print(f"[{'OK' if code == 0 else 'FAIL'}] format: {message}")
    if code:
        return code
    count, problems = check_labels(data.decode("ascii").split("\r\n"))
    for problem in problems:
        print(f"[FAIL] {problem}")
    if problems:
        return 1
    print(f"[OK] labels: {count} unique, every goto/call target exists, every label reachable")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1] if len(sys.argv) > 1 else "All in One.cmd"))
