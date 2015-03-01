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
	.addr	TBlock_0
	.addr	TBlock_1
	.addr	TBlock_2
	.addr	TBlock_3
	.addr	JBlock_0
	.addr	JBlock_1
	.addr	JBlock_2
	.addr	JBlock_3
	.addr	ZBlock_0
	.addr	ZBlock_1
	.addr	ZBlock_2
	.addr	ZBlock_3
	.addr	Square
	.addr	Square
	.addr	Square
	.addr	Square
	.addr	SBlock_0
	.addr	SBlock_1
	.addr	SBlock_2
	.addr	SBlock_3
	.addr	LBlock_0
	.addr	LBlock_1
	.addr	LBlock_2
	.addr	LBlock_3
	.addr	IBlock_0
	.addr	IBlock_1
	.addr	IBlock_2
	.addr	IBlock_3


.global Pieces__COUNT
Pieces__COUNT = (* - Table) / 2


TBlock_0:
	.addr	TBlock_3
	.addr	TBlock_1

	.word	0 * 2
	.byte	1

	.byte	1, 3, 0, 0

	.word	12, 12

	.byte	" *  "
	.byte	"*** "
	.byte	"    "
	.byte	"    "

TBlock_1:
	.addr	TBlock_0
	.addr	TBlock_2

	.word	0 * 2
	.byte	1

	.byte	1, 2, 1, 0

	.word	12, 12

	.byte	" *  "
	.byte	"**  "
	.byte	" *  "
	.byte	"    "

TBlock_2:
	.addr	TBlock_1
	.addr	TBlock_3

	.word	0 * 2
	.byte	1

	.byte	0, 3, 1, 0

	.word	12, 12

	.byte	"    "
	.byte	"*** "
	.byte	" *  "
	.byte	"    "

TBlock_3:
	.addr	TBlock_2
	.addr	TBlock_0

	.word	0 * 2
	.byte	1

	.byte	1, 2, 1, 0

	.word	12, 12

	.byte	" *  "
	.byte	" ** "
	.byte	" *  "
	.byte	"    "



JBlock_0:
	.addr	JBlock_3
	.addr	JBlock_1

	.word	1 * 2
	.byte	2

	.byte	1, 3, 0, 0

	.word	12, 12

	.byte	"*   "
	.byte	"*** "
	.byte	"    "
	.byte	"    "

JBlock_1:
	.addr	JBlock_0
	.addr	JBlock_2

	.word	1 * 2
	.byte	2

	.byte	2, 1, 1, 0

	.word	12, 12

	.byte	" ** "
	.byte	" *  "
	.byte	" *  "
	.byte	"    "

JBlock_2:
	.addr	JBlock_1
	.addr	JBlock_3

	.word	1 * 2
	.byte	2

	.byte	0, 3, 1, 0

	.word	12, 12

	.byte	"    "
	.byte	"*** "
	.byte	"  * "
	.byte	"    "

JBlock_3:
	.addr	JBlock_2
	.addr	JBlock_0

	.word	1 * 2
	.byte	2

	.byte	1, 1, 2, 0

	.word	12, 12

	.byte	" *  "
	.byte	" *  "
	.byte	"**  "
	.byte	"    "



ZBlock_0:
	.addr	ZBlock_3
	.addr	ZBlock_1

	.word	2 * 2
	.byte	2

	.byte	2, 2, 0, 0

	.word	12, 12

	.byte	"**  "
	.byte	" ** "
	.byte	"    "
	.byte	"    "

ZBlock_1:
	.addr	ZBlock_0
	.addr	ZBlock_2

	.word	2 * 2
	.byte	2

	.byte	1, 2, 1, 0

	.word	12, 12

	.byte	"  * "
	.byte	" ** "
	.byte	" *  "
	.byte	"    "

ZBlock_2:
	.addr	ZBlock_1
	.addr	ZBlock_3

	.word	2 * 2
	.byte	2

	.byte	0, 2, 2, 0

	.word	12, 12

	.byte	"    "
	.byte	"**  "
	.byte	" ** "
	.byte	"    "

ZBlock_3:
	.addr	ZBlock_2
	.addr	ZBlock_0

	.word	2 * 2
	.byte	2

	.byte	1, 2, 1, 0

	.word	12, 12

	.byte	" *  "
	.byte	"**  "
	.byte	"*   "
	.byte	"    "



Square:
	.addr	Square
	.addr	Square

	.word	3 * 2
	.byte	1

	.byte	2, 2, 0, 0

	.word	8, 8

	.byte	" ** "
	.byte	" ** "
	.byte	"    "
	.byte	"    "



SBlock_0:
	.addr	SBlock_3
	.addr	SBlock_1

	.word	4 * 2
	.byte	3

	.byte	2, 2, 0, 0

	.word	12, 12

	.byte	" ** "
	.byte	"**  "
	.byte	"    "
	.byte	"    "

SBlock_1:
	.addr	SBlock_0
	.addr	SBlock_2

	.word	4 * 2
	.byte	3

	.byte	1, 2, 1, 0

	.word	12, 12

	.byte	" *  "
	.byte	" ** "
	.byte	"  * "
	.byte	"    "

SBlock_2:
	.addr	SBlock_1
	.addr	SBlock_3

	.word	4 * 2
	.byte	3

	.byte	0, 2, 2, 0

	.word	12, 12

	.byte	"    "
	.byte	" ** "
	.byte	"**  "
	.byte	"    "

SBlock_3:
	.addr	SBlock_2
	.addr	SBlock_0

	.word	4 * 2
	.byte	3

	.byte	1, 2, 1, 0

	.word	12, 12

	.byte	"*   "
	.byte	"**  "
	.byte	" *  "
	.byte	"    "



LBlock_0:
	.addr	LBlock_3
	.addr	LBlock_1

	.word	5 * 2
	.byte	3

	.byte	1, 3, 0, 0

	.word	12, 12

	.byte	"  * "
	.byte	"*** "
	.byte	"    "
	.byte	"    "

LBlock_1:
	.addr	LBlock_0
	.addr	LBlock_2

	.word	5 * 2
	.byte	3

	.byte	1, 1, 2, 0

	.word	12, 12

	.byte	" *  "
	.byte	" *  "
	.byte	" ** "
	.byte	"    "

LBlock_2:
	.addr	LBlock_1
	.addr	LBlock_3

	.word	5 * 2
	.byte	3

	.byte	0, 3, 1, 0

	.word	12, 12

	.byte	"    "
	.byte	"*** "
	.byte	"*   "
	.byte	"    "

LBlock_3:
	.addr	LBlock_2
	.addr	LBlock_0

	.word	5 * 2
	.byte	3

	.byte	2, 1, 1, 0

	.word	12, 12

	.byte	"**  "
	.byte	" *  "
	.byte	" *  "
	.byte	"    "



IBlock_0:
	.addr	IBlock_3
	.addr	IBlock_1

	.word	6 * 2
	.byte	4

	.byte	0, 4, 0, 0

	.word	16, 16

	.byte	"    "
	.byte	"****"
	.byte	"    "
	.byte	"    "

IBlock_1:
	.addr	IBlock_0
	.addr	IBlock_2

	.word	6 * 2
	.byte	4

	.byte	1, 1, 1, 1

	.word	16, 16

	.byte	"  * "
	.byte	"  * "
	.byte	"  * "
	.byte	"  * "

IBlock_2:
	.addr	IBlock_1
	.addr	IBlock_3

	.word	6 * 2
	.byte	4

	.byte	0, 0, 4, 0

	.word	16, 16

	.byte	"    "
	.byte	"    "
	.byte	"****"
	.byte	"    "

IBlock_3:
	.addr	IBlock_2
	.addr	IBlock_0

	.word	6 * 2
	.byte	4

	.byte	1, 1, 1, 1

	.word	16, 16

	.byte	" *  "
	.byte	" *  "
	.byte	" *  "
	.byte	" *  "


ENDMODULE


