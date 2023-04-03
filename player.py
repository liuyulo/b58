#!venv/bin/python
from PIL import Image
from PIL.Image import Transpose
from argparse import ArgumentParser

# global constants in assembly
BASE = 'BASE_ADDRESS'
WIDTH = 512
BACKGROUND = 'BACKGROUND'


def pr(s: str, indent: int = 1):
    a = (t.removeprefix('    ') for t in s.split('\n'))
    tab = ' ' * (4 * indent)
    print(tab + ('\n' + tab).join(a))


def clean(w: int, h: int):
    pr('''
    # clean previous, a3 is previous top left corner
    beqz $a1 clear_row_end # no movement on y axis
    move $t0 $a3
    bgez $a1 clear_row # skip shift
        addi $t2 $a1 PLAYER_SIZE
        sll $t2 $t2 WIDTH_SHIFT
        add $t0 $t0 $t2 # shift to bottom row
    clear_row:''')

    for i in range(w):
        pr(f'sw BACKGROUND {i * 4}($t0) # clear ({i}, y)', 2)

    pr('''\tclear_row_end:
    beqz $a0 clear_end # no movement on x axis
    bgez $a0 clear_column # skip shift
        add $a3 $a3 $a0
        addi $a3 $a3 PLAYER_SIZE # shift to right column
    clear_column:''')

    pr(f'sw BACKGROUND 0($a3) # clear (x, 0)', 2)
    for i in range(1, h):
        pr(f'sw BACKGROUND {i*WIDTH}($a3) # clear (x, {i})', 2)

    pr('clear_end:')


def draw(im):
    w, _ = im.size
    for i, color in enumerate(im.getdata()):
        if not color[3]:
            # transparent
            continue
        color = '0x%02x%02x%02x' % color[:3]
        x, y = i % w, i // w
        pos = y * WIDTH + x * 4
        if color == '0x000000':
            pr(f'sw {BACKGROUND} {pos}($v0) # store background ({x}, {y})')
        else:
            pr(f'li $t0 {color} # load color')
            pr(f'sw $t0 {pos}($v0) # store color ({x}, {y})')


def main(args):
    im = Image.open(args.path)
    w, h = im.size
    # im = im.transpose(Transpose.ROTATE_270)

    draw(im)
    clean(w, h)
    pr('jr $ra # return')


if __name__ == '__main__':
    parser = ArgumentParser(description='draw player')
    parser.add_argument('path', help='path to player image')
    args = parser.parse_args()
    main(args)
