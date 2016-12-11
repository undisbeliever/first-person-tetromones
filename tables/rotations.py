#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# vim: set fenc=utf-8 ai ts=4 sw=4 sts=4 et:

import math

N_FRAMES = 10
SCALE = 1.0

def f_to_hex(f):
    i = int(f * 256)
    if i < 0:
        i = 0x10000 + i
    if i > 0xFFFF:
        i %= 0xFFFF
    return "$%04X" % i


def print_matrix(r):
    # [ cos(r)·(1/s)  -sin(r)·(1/s) ]  [ A  B ]
    # [ sin(r)·(1/s)   cos(r)·(1/s) ]  [ C  D ]

    a = math.cos(r) * (1 / SCALE)
    b = -math.sin(r) * (1 / SCALE)
    c = math.sin(r) * (1 / SCALE)
    d = math.cos(r) * (1 / SCALE)

    ah = f_to_hex(a)
    bh = f_to_hex(b)
    ch = f_to_hex(c)
    dh = f_to_hex(d)

    rd = "%1.0f" % math.degrees(r)

    print("\t .word", ah, ",", bh, ",", ch, ",", dh, "; r =", rd)



def calc_rotations(number, start):
    print("LABEL RotateTable_{}".format(number))

    r = math.radians(start)
    end = r + math.radians(90)
    step = math.radians(90) / (N_FRAMES - 1)

    for i in range(N_FRAMES - 1):
        print_matrix(r)
        r += step

    print_matrix(end)

    print()



def main():
    print("CONST N_ROTATION_FRAMES,", N_FRAMES)
    print()
    print("LABEL RotationTable")
    for i in range(4):
        print("\t.addr RotateTable_{}".format(i))
    print()
    print()

    calc_rotations(0,   0)
    calc_rotations(1,  90)
    calc_rotations(2, 180)
    calc_rotations(3, 270)


if __name__ == '__main__':
    main()
