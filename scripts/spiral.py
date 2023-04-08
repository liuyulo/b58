#!venv/bin/python
from PIL import Image
from itertools import chain
from collections import OrderedDict
from argparse import ArgumentParser

WIDTH = 512


def pr(s: str):
    print('    ' + s)


def main(args):
    path = args.path
    im = Image.open(path).convert('RGBA')
    size, _ = im.size
    d = OrderedDict()
    for i, color in enumerate(im.getdata()):
        color = '0x%02x%02x%02x' % color[:3]
        x, y = i % size, i // size
        if color not in d:
            d[color] = []
        d[color].append((x, y))
    # from inside to outside
    for i, (_, arr) in enumerate(reversed(d.items())):
        print(f'draw_clear_{i:02d}: # draw t4, sleep, draw 0')
        for x, y in arr:
            pos = x * 4 + y * WIDTH
            pr(f'sw $t4 {pos}($v1) # draw ({x}, {y})')
        pr('beqz $t4 jrra # return')
        pr('syscall # sleep')
        pr('move $t4 $0')
        pr(f'j draw_clear_{i:02d}')


if __name__ == '__main__':
    parser = ArgumentParser(description='convert spiral image to asm')
    parser.add_argument('path', help='path to spiral image')
    args = parser.parse_args()
    main(args)
