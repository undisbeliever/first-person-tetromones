
TABLES = rotations.inc level-colors.inc

.PHONY: ALL

ALL: $(TABLES)

%.inc: %.py
	python3 $< >| $@

.PHONY: clean
	$(RM) $(TABLES)

