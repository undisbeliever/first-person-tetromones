
.include "resources.h"
.setcpu "65816"

.rodata
	; The game field is loaded in `ui.s`

	INCLUDE_BINARY gameFieldTiles,		"resources/game-field.pc7"
	INCLUDE_BINARY gameFieldPalette,	"resources/game-field.clr"


