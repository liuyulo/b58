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
        li $t2 PLAYER_END
        sll $t2 $t2 WIDTH_SHIFT
        add $t0 $t0 $t2 # shift to bottom row
    clear_row:''')

    for i in range(w):
        pr(f'sw BACKGROUND {i * 4}($t0) # clear ({i}, y)', 2)

    pr('''\tclear_row_end:
    beqz $a0 clear_end # no movement on x axis
    bgez $a0 clear_column # skip shift
        addi $a3 $a3 PLAYER_END # shift to right column
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
        if x == 0 and i != 0:
            pr(f'add $t2 $t2 $t1 # shift y')
            pr(f'move $t3 $t2 # carriage return')
        # pos = y * WIDTH + x * 4
        if color == '0x000000':
            pr(f'sw {BACKGROUND} 0($t3) # store background ({x}, {y})')
        else:
            pr(f'li $t4 {color} # load color')
            pr(f'sw $t4 0($t3) # store color ({x}, {y})')
        pr(f'add $t3 $t3 $t0 # shift x')


def main(args):
    im = Image.open(args.path)
    w, h = im.size
    # im = im.transpose(Transpose.ROTATE_270)
    pr('''# binary seach go brrr
    beqz $s3 draw_c # draw columns first
        bltz $s3 draw_rn # draw rows towards north
            li $t1 SIZE
            move $t2 $v0
            bltz $s4 draw_rsw # draw rows south west
                li $t0 4  # draw rows south east
                j draw_end
            draw_rsw:
                li $t0 -4  # draw rows south west
                addi $t2 $t2 PLAYER_END
                j draw_end
        draw_rn: # draw rows north
            li $t1 -SIZE
            li $t2 PLAYER_END # set t2 to bottom left
            sll $t2 $t2 WIDTH_SHIFT
            add $t2 $t2 $v0
            bltz $s4 draw_rnw # draw rows north west
                li $t0 4  # draw rows north east
                j draw_end
            draw_rnw: # draw rows north west
                li $t0 -4
                addi $t2 $t2 PLAYER_END
                j draw_end
            j draw_end
    draw_c: # draw columns
        bltz $s2 draw_cw # draw columns west
            li $t1 4
            bltz $s4 draw_cen # draw columns east north
                li $t0 SIZE  # draw columns east south
                move $t2 $v0
                j draw_end
            draw_cen: # draw columns east north
                li $t0 -SIZE
                li $t2 PLAYER_END # set t2 to bottom left
                sll $t2 $t2 WIDTH_SHIFT
                add $t2 $t2 $v0
                j draw_end
        draw_cw: # draw columns west
            li $t1 -4
            bltz $s4 draw_cwn # draw columns west north
                li $t0 SIZE  # draw columns west south
                addi $t2 $v0 PLAYER_END # set t2 to top right
                j draw_end
            draw_cwn:
                li $t0 -SIZE
                li $t2 PLAYER_END # set t2 to bottom right
                sll $t2 $t2 WIDTH_SHIFT
                add $t2 $t2 $v0
                addi $t2 $t2 PLAYER_END
                j draw_end
    draw_end:

    move $t3 $t2 # t3 tracks position''')
    draw(im)
    clean(w, h)
    pr('jr $ra # return')


if __name__ == '__main__':
    parser = ArgumentParser(description='draw player')
    parser.add_argument('path', help='path to player image')
    args = parser.parse_args()
    main(args)
