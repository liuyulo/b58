#!venv/bin/python
from collections.abc import Iterable
from PIL import Image
import os
from argparse import ArgumentParser

WIDTH = 512
POINTER = 'v1'

COLORS = {
    0x2d260f: 0,
    0x453917: 1,
    0x5e4e1f: 2,
    0x756127: 3,
    0x8b742e: 4,
    0xa98c38: 5,
    0xba9b3e: 6,
    0xd0ad45: 7,
    0xe6c04c: 8,
    0xfad053: 9,
    0: 10,
}


def draw(im) -> Iterable[str]:
    w, _ = im.size
    # color to positions
    data = {}
    for i, color in enumerate(im.getdata()):
        if color[3] == 0:
            continue
        color = color[0] << 16 | color[1] << 8 | color[2]
        color = min(COLORS, key=lambda x: abs(color - x))
        if color not in data:
            data[color] = []
        x, y = i % w, i // w
        data[color].append((x, y))
    for color, pos in data.items():
        register = '$0' if color == 0 else f'$t{COLORS[color]}'
        # register = '$0' if color == 0 else f'$t4'
        # if color != 0:
        #     yield f'li $t4 0x{color:06x}'
        for x, y in pos:
            p = x * 4 + y * WIDTH
            yield f'sw {register} {p}(${POINTER}) # ({x}, {y})'
    yield 'jr $ra'


def clear(im) -> Iterable[str]:
    w, h = im.size
    for y in range(0, h * WIDTH, WIDTH):
        for x in range(0, w * 4, 4):
            yield f'sw $0 {x+y}(${POINTER})'
    yield 'jr $ra'


def main(args):
    paths = args.path
    for path in paths:
        name = os.path.splitext(os.path.basename(path))[0]
        name = name.replace('-', '_')
        im = Image.open(path).convert('RGBA')
        if args.clear:
            name = f'clear_{name}'
            fn = clear
        else:
            name = f'draw_{name}'
            fn = draw
        print(f'{name}: # start at {POINTER}, use t4', end='\n    ')
        print('\n    '.join(fn(im)))


if __name__ == '__main__':
    parser = ArgumentParser(
        description='print intructions for drawing an image')
    parser.add_argument('path', help='path to image', nargs='+')
    parser.add_argument('--clear',
                        help='print instructions for clear',
                        default=False,
                        action='store_true')
    args = parser.parse_args()
    main(args)
