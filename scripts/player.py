#!venv/bin/python
from PIL import Image
import os
from argparse import ArgumentParser

# global constants in assembly
BASE = 'BASE_ADDRESS'
WIDTH = 512


def pr(s: str, indent: int = 1):
    a = (t.removeprefix('    ') for t in s.split('\n'))
    tab = ' ' * (4 * indent)
    print(tab + ('\n' + tab).join(a))


def draw(im):
    w, _ = im.size
    for i, color in enumerate(im.getdata()):
        if not color[3]:
            # transparent
            continue
        color = '0x%02x%02x%02x' % color[:3]
        x, _ = i % w, i // w

def main(args):
    for path in args.path:
        name = os.path.splitext(os.path.basename(path))[0]
        name = name.replace('-', '_')
        im = Image.open(path).convert('RGBA')
        print(f'draw_{name}: # start at v1')
        w, _ = im.size
        for i, color in enumerate(im.getdata()):
            x, _ = i % w, i // w
            r, g, b, a = color
            if x == 0 and i != 0:
                print(')')
            if x == 0:
                print('    draw16x1($t4, $t0, $t2, $t1', end='')
            if a * (r + g + b) == 0:
                color = '0'
            else:
                color = '0x%02x%02x%02x' % (r, g, b)
            print(',', color, end='')
        print(')')
        print('    jr $ra # return')


if __name__ == '__main__':
    parser = ArgumentParser(description='draw player')
    parser.add_argument('path', help='paths to player image', nargs='+')
    args = parser.parse_args()
    main(args)
