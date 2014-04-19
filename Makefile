EXTENSION   = base36 base36_gist
MODULES     = base36
DATA        = base36--1.0.sql base36.control         \
              base36_gist--1.0.sql base36_gist.control

LDFLAGS=-lrt

PG_CONFIG ?= pg_config
PGXS = $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)
