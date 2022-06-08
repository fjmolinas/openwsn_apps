.PHONY: all clean build init-submodules

APPLICATIONS =      \
    openwsn_only \
    openwsn_suit \
	#

all: build

clean:
	for app in $(APPLICATIONS); do make -C $$app distclean; done

build:
	for app in $(APPLICATIONS); do make -C $$app all; done

init-submodules:
	@git submodule update --init --recursive
	@git submodule update

