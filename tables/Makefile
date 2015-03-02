
TABLES = rotations.inc level-colors.inc

.PHONY: ALL

ALL: $(TABLES)

%.inc: %.py
	python3 $< >| $@

