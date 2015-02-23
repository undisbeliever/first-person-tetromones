; First Person Tetromones
; Game pieces

.include "routines/block.h"
.include "routines/screen.h"

.include "pieces.h"
.include "fptetromones.h"
.include "ui.h"


MODULE Pieces

.rodata

LABEL Table
	.addr	SquareLeft
	.addr	SquareLeft
	.addr	SquareRight
	.addr	SquareRight
	.addr	TBlock_0
	.addr	TBlock_1
	.addr	TBlock_2
	.addr	TBlock_3


CONST COUNT, (* - Table) / 2


SquareLeft:
	.addr	SquareLeft
	.addr	SquareLeft

	.word	3 * 2
	.byte	1

	.byte	0
	.byte	2

	.byte	0, 2, 2, 0

	.byte	"    "
	.byte	"**  "
	.byte	"**  "
	.byte	"    "

SquareRight:
	.addr	SquareRight
	.addr	SquareRight

	.word	3 * 2
	.byte	1

	.byte	1
	.byte	3

	.byte	0, 2, 2, 0

	.byte	"    "
	.byte	" ** "
	.byte	" ** "
	.byte	"    "


TBlock_0:
	.addr	TBlock_3
	.addr	TBlock_1

	.word	0 * 2
	.byte	1

	.byte	0
	.byte	3

	.byte	1, 3, 0, 0

	.byte	" *  "
	.byte	"*** "
	.byte	"    "
	.byte	"    "

TBlock_1:
	.addr	TBlock_0
	.addr	TBlock_2

	.word	0 * 2
	.byte	1

	.byte	0
	.byte	2

	.byte	1, 2, 1, 0

	.byte	" *  "
	.byte	"**  "
	.byte	" *  "
	.byte	"    "

TBlock_2:
	.addr	TBlock_1
	.addr	TBlock_3

	.word	0 * 2
	.byte	1

	.byte	0
	.byte	3

	.byte	0, 3, 1, 0

	.byte	"    "
	.byte	"*** "
	.byte	" *  "
	.byte	"    "

TBlock_3:
	.addr	TBlock_2
	.addr	TBlock_0

	.word	0 * 2
	.byte	1

	.byte	1
	.byte	3

	.byte	1, 2, 1, 0

	.byte	" *  "
	.byte	" ** "
	.byte	" *  "
	.byte	"    "


ENDMODULE


