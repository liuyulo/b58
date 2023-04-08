#!venv/bin/python
from argparse import ArgumentParser
import mido

tempo = mido.bpm2tempo(132)
e = (60_000 / 132) / 8
fps = int(e)


def msg(message, tpb):
    pitch = message.note
    dur = message.time
    ms = 1000 * mido.tick2second(dur, tpb, tempo)
    ms = round(ms / e) * fps
    print(pitch, ms)
    # print('\nli $v0 31')
    # print('li $a0', pitch)
    # print('li $a1', ms)
    # print('syscall')
    # print('li $v0 32')
    # print(f'li $a0 {ms}')
    # print('syscall')


def head():
    print('.text')
    print('.globl main')
    print('main:')
    print('li $a2 1')
    print('li $a3 50')


def main(args):
    # head()
    f = mido.MidiFile(args.path)
    track = f.tracks[0]
    i = 0
    for message in track:
        if i >= 215:
            return
        # print(message)
        if message.type == 'note_off' and message.time > 0:
            if i == 65:
                print(0, 448)
                # print('\n# rest')
                # print('li $v0 32')
                # print('li $a0 448')
                # print('syscall')
            msg(message, f.ticks_per_beat)
            i += 1


if __name__ == '__main__':
    parser = ArgumentParser(description='print midi info')
    parser.add_argument('path', help='path to midi')
    args = parser.parse_args()
    main(args)
