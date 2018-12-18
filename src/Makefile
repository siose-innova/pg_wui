EXTENSION = pg_wui
DATA = pg_wui--0.2.sql
TEMPLATE = $(DATA).template

$(DATA) : $(TEMPLATE)
	sed "s/\$$SIOSE_SCHEMA/$(SIOSE_SCHEMA)/g" $< > $@

PG_CONFIG = pg_config
PGXS := $(shell $(PG_CONFIG)  --pgxs)
include $(PGXS)
