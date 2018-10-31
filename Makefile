# Prepares a container environment in order to
# save a Docker image that provides a SIOSE
# database instance with pg_wui extension.

# REQUIREMENTS:
# 1. An ext-creator image must be properly
#    compiled and registered with a name
#    that matches the image name for ext-creator
#    service in docker-compose.yml.template.
#    To compile an ext-creator image use
#    lib/ext-creator/[VERSION]/Dockerfile
#    in this repository.
# 2. A SIOSE Docker image must be properly
#    compiled and its registered name assigned
#    to Makefile variable BASE. An instance of
#    this image must provide a SIOSE database
#    which is compliant with the MF2 data model.


COMPOSE = docker-compose.yml
TEMPLATE = $(COMPOSE).template
VERSION = 0.1
# Assign values as needed to vars below.
# Then run:
# $ make clean
# $ make
# $ sudo make install
# $ docker-compose up
# To save the final image, run the following
# on a separate shell:
# $ docker commit pg_wui_host [NEW_IMAGE_NAME]
# $ docker-compose down

# SUBTAG for new Docker image.
# The outcome of `sudo make install`
# will be a new Docker image named 
# siose-innova/preinstalled-pg_wui:$VERSION-$SUBTAG
# where $SUBTAG may follow a convention such as
# [SIOSE_AREA_EXTENT]_[YYYY].
# Valid values for the term [SIOSE_AREA_EXTENT]
# Geohash strings and administrative boundary codes.
SUBTAG = 1012_2005

# BASE Docker image.
# This must be a SIOSE database instance compliant
# with the MF2 data model. Database instances may
# cover the whole or part of SIOSE's extension.
BASE = siose-innova/mf2-1012:2005

# DB name.
# This is the name of the target SIOSE database
# within BASE image.
DB = siose2005

# SCHEMA name.
# This is the name of the target schema in DB.
SCHEMA = s2005

$(COMPOSE) : $(TEMPLATE)
	sed -e "s/\$$VERSION/$(VERSION)/g" \
            -e "s/\$$SUBTAG/$(SUBTAG)/g" \
            -e "s/\$$BASE/$(subst /,\/,$(BASE))/g" \
            -e "s/\$$DB/$(DB)/g" \
            -e "s/\$$SCHEMA/$(SCHEMA)/g" $< > $@

.PHONY: install clean

install :
	docker-compose build

clean : 
	rm -f $(COMPOSE)
