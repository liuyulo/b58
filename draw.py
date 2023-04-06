#!venv/bin/python
from collections.abc import Iterable
from PIL import Image
import os
from argparse import ArgumentParser

WIDTH = 512
POINTER = 'v1'


def draw(im) -> Iterable[str]:
    w, _ = im.size
    # color to positions
    data = {}
    for i, color in enumerate(im.getdata()):
        if color[3] == 0:
            color = (0, 0, 0)
        color = '0x%02x%02x%02x' % color[:3]
        if color not in data:
            data[color] = []
        x, y = i % w, i // w
        pos = x * 4 + y * WIDTH
        data[color].append(pos)
    for color, pos in data.items():
        print(color)
        register = '$0' if color == '0x000000' else '$t4'
        if color != '0x000000':
            yield f'li $t4 {color}'
        for p in pos:
            x, y = (p % WIDTH) // 4, p // WIDTH
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
