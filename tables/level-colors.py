#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# vim: set fenc=utf-8 ai ts=4 sw=4 sts=4 et:

from colorsys import hsv_to_rgb

SAT_VAL_PER_TILE_COLOR = (
    (1.00, 1.00),
    (0.71, 1.00),
    (1.00, 0.65),
    (1.00, 0.78),
    (1.00, 0.89)
)

HUES_PER_LEVEL = (
    ( 48,  88, 208,   8, 328),  # 1
    (220,  33, 153,   8, 328),  # 2
    (265,  85, 175,   8, 328),  # 3
    ( 60, 100, 220,   8, 328),  # 4
    ( 87, 207, 277,   8, 328),  # 5
    ( 55,  95, 225,   8, 328),  # 6
    (138,  48, 248,   8, 328),  # 7
    (330,  80, 160,   8, 328),  # 8
    (242,  42, 192,   8, 328),  # 9
    ( 60, 180, 120,   8, 328),  # 10
)


def hsv_to_snes(h, s, v):
    hv = (h % (360 - 1)) / 360

    rgb = hsv_to_rgb(hv, s, v)
    r, g, b = [int(31 * f) for f in rgb]

    s = b << 10 | g << 5 | r

    return "$%04X" % s


def print_tile_colors(hue):
    palette = []

    for s, v in SAT_VAL_PER_TILE_COLOR:
        palette.append(hsv_to_snes(hue, s, v))

    print("\t.word", ", ".join(palette))


def level_palette_label(level_number):
    return "LevelPalette_%i" % level_number


def print_level_colors(level_number, level_hues):
    print("LABEL", level_palette_label(level_number))
    for hue in level_hues:
        print_tile_colors(hue)

    print()


def main():
    print("N_LEVEL_PALETTES =", len(HUES_PER_LEVEL))
    print()

    print("LABEL LevelPaletteTable")
    for level, level_hues in enumerate(HUES_PER_LEVEL, start=1):
        print("\t.addr", level_palette_label(level))

    print("\n")

    for level, level_hues in enumerate(HUES_PER_LEVEL, start=1):
        print_level_colors(level, level_hues)


if __name__ == '__main__':
    main()

