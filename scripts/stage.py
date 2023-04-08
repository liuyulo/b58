#!venv/bin/python
# from PIL import Image
import random
import itertools
from argparse import ArgumentParser

# global constants in assembly
BASE = 'BASE_ADDRESS'
WIDTH = 512 // 4  # width in pixels
WOOD = [
    '0x887143', '0xaf8f55', '0xc29d62', '0x967441', '0x9f844d', '0x7d6739',
    '0x7e6237', '0x846d40', '0xb8945f'
]

# bounding boxes, in unit of 4 pixels or 16 bytes, inclusive
ST = [
    [
        (0, 6, 7, 6),  # top left floor stage 0
        (13, 25, 18, 25),  # bottom center floating
        (0, 31, 7, 31),  # bottom left
        (25, 31, 31, 31),  # bottom right
    ],
    [
        (0, 0, 10, 0),  # top left floor stage 1
        (1, 11, 1, 14),  # left conter
    ],
    [
        (1, 2,1, 4),  # top left for stage 2
        (0, 27, 0, 30),  # bottom left
        (14, 26, 14, 27)
    ],
    [(13, 7, 13, 19)  # middle bar
     ],
    [
        (14, 28, 14, 31),  # extra
        (19, 18, 19, 25)
    ]
]
# boxes boundary in bytes, exclusive
STAGE = [[(x1 * 16, y1 * 16, (x2 + 1) * 16, (y2 + 1) * 16)
          for x1, y1, x2, y2 in ps] for ps in ST]


def data():
    print('# inclusive bounding boxes (x1, y1, x2, y2), each bbox is 16 bytes')
    print('platforms: .word', end='')
    for platform in itertools.chain.from_iterable(STAGE):
        x1, y1, x2, y2 = platform
        # make inclusive
        print(f' {x1} {y1} {x2-4} {y2-4}', end='')
    print('\n# address to end of platforms per stage')
    print('platforms_end: .word', end='')
    s = 0
    for st in ST:
        s += len(st)
        print(f' {s*16}', end='')
    print()


def pr(s: str):
    print('    ' + s)


def platform(x1: int, y1: int, x2: int, y2: int):
    for y in range(y1, y2, 4):
        for x in range(x1, x2, 4):
            i = random.randrange(0, len(WOOD))
            # position in bytes
            pos = y * WIDTH + x
            pr(f'sw $t{i} {pos}($v1)')


def main(args):
    if args.data:
        data()
        return
    print('draw_stage: # use t0-t9 v1')
    pr(f'lw $t9 stage')
    pr(f'li $v1 {BASE}')
    pr('li $a0 REFRESH_RATE')
    pr('sll $a0 $a0 3')
    pr('li $v0 32')
    for i, color in enumerate(WOOD):
        pr(f'li $t{i} {color}')
    for i, ps in enumerate(STAGE):
        for p in ps:
            platform(*p)
            pr('syscall # sleep')
        if i != len(STAGE) - 1:
            pr(f'beq $t9 {i*4} jrra # end of stage {i}')
    pr('')
    pr('jr $ra # return')


if __name__ == '__main__':
    parser = ArgumentParser(description='draw stage')
    parser.add_argument('--data',
                        '-d',
                        help='print .data',
                        action='store_true')
    args = parser.parse_args()
    main(args)
