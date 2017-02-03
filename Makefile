CFLAGS = -Wall -Wextra -Werror -framework IOBluetooth

DESTDIR =
prefix = /usr/local
bindir = $(prefix)/bin
INSTALL = install
INSTALL_PROGRAM = $(INSTALL) -m 755

build: blueutil

test: build
	./test

clean:
	$(RM) blueutil

install: build
	@echo $(INSTALL_PROGRAM) blueutil $(DESTDIR)$(bindir)/blueutil

uninstall:
	@echo $(RM) $(DESTDIR)$(bindir)/blueutil

.PHONY: build test clean install uninstall
