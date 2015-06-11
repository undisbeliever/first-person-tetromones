
ROM_NAME      = First_Person_Tetromones
CONFIG        = LOROM_1MBit_copyright
API_MODULES   = reset-snes block screen math random
API_DIR       = snesdev-common
SOURCE_DIR    = src
TABLES_DIR    = tables
RESOURCES_DIR = resources

include $(API_DIR)/Makefile.in

