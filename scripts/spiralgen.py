#!venv/bin/python
from PIL import Image, ImageOps
from argparse import ArgumentParser
import itertools
import math

RE = Image.NEAREST


def calculate(th: float):
    r = math.sin(th * math.pi / 180)**2
    a = r - math.sqrt(r - r**2)
    return a / (2 * r - 1)


def spiral(size: int, theta, n, v: float):
    base = Image.new('RGBA', (size, size), next(colors))
    th = theta
    s = size
    for i in range(n - 1):
        a = s * v
        b = s * (1 - v)
        s = int(math.sqrt(a * a + b * b))
        im = Image.new('RGBA', (s, s), next(colors))
        im = im.rotate(th,
                       expand=True,
                       center=(s / 2, s / 2),
                       resample=RE,
                       fillcolor=(0, 0, 0, 0))
        w, _ = im.size
        im = ImageOps.expand(im, border=(size - w) // 2, fill=(0, 0, 0, 0))
        print(im.size)
        base.paste(im, (0, 0), im)
        th += theta
    return base


colors = itertools.cycle((i, i, i) for i in range(255))


def main(args):
    theta = args.total / args.iter
    global colors
    colors = itertools.cycle(
        (i, i, i) for i in range(0, 255, 255 // args.iter))
    im = spiral(args.size, theta, args.iter, calculate(theta))
    im.save(f'spiral-{args.iter}.png')


if __name__ == '__main__':
    parser = ArgumentParser()
    parser.add_argument('size', type=int, help='width and height')
    parser.add_argument('total', type=int, help='total angle to rotate (deg)')
    parser.add_argument('iter', type=int, help='number of iterations')

    args = parser.parse_args()
    main(args)
