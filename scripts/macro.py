#!venv/bin/python
import sys, re
from argparse import ArgumentParser

sw = re.compile(r'\s+sw (\$t?\d) (\d+)\(\$v1\)')
li = re.compile(r'\s+li \$t4 (0x[0-9a-f]+)')

dfsai: dict[tuple[int, str], int] = {(0, 'sw'): 0}
dfsac: dict[tuple[int, str], int] = {(0, 'li'): 1, (1, 'sw'): 0}
qi, qc = 0, 0  # state

colors: list[tuple[int, int]] = []
color: int = 0
imms: list[int] = []
rs = ''


def pr(*args, **kwargs):
    print(*args, **kwargs, file=sys.stderr)


def instr(line: str):
    return line.split(maxsplit=1)[0]


def consume_i():
    global imms, rs
    if len(imms) < 2:
        # let consume_c handle it
        return imms.clear()
    if color != 0:
        print(f'    li {rs} 0x{color:06x}')
    n = 1024
    while imms and n:
        if len(imms) < 4:
            for i in imms:
                print(f'    sw {rs} {i}($v1)')
            break
        if len(imms) < n:
            n >>= 2
            continue
        args = ', '.join(map(str, imms[:n]))
        print(f'    draw{n}({rs}, {args})')
        imms = imms[n:]
    imms.clear()


def consume_c():
    global colors
    n = 512
    if len(colors) < 2:
        return colors.clear()
    while colors and n:
        if len(colors) < 2:
            for color, imm in colors:
                print(f'    li $t4 0x{color:06x}')
                print(f'    sw $t4 {imm}($v1)')
            break
        if len(colors) < n:
            n >>= 2
            continue
        args = ', '.join(f'0x{c:06x}, {i}' for c, i in colors[:n])
        print(f'    draw{n}($t4, {args})')
        colors = colors[n:]
    colors.clear()


def proc_i(line):
    global imms, rs
    if not (m := sw.match(line)):
        return
    if (r := m.group(1)) != rs:
        consume_i()
        rs = r
    i = int(m.group(2))
    imms.append(i)


def proc_c(line):
    global colors, color
    if (mi := li.match(line)):
        color = int(mi.group(1), 16)
    elif (ms := sw.match(line)):
        i = int(ms.group(2))
        colors.append((color, i))


def main():
    global qi, qc
    while (line := sys.stdin.readline().rstrip()):
        # input to DFSA
        a = instr(line)
        if (qi, a) in dfsai:
            proc_i(line)
            qi = dfsai[qi, a]
        else:
            qi = 0
            consume_i()
        if (qc, a) in dfsac:
            proc_c(line)
            qc = dfsac[qc, a]
        else:
            qc = 0
            consume_c()
        if a not in ('sw', 'li'):
            print(line)


if __name__ == '__main__':
    parser = ArgumentParser(description='compress asm code from stdin with macros')
    main()
