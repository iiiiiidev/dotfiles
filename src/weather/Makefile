PKGS    = gtk4 libsoup-3.0 json-glib-1.0
CFLAGS += -Wall -Wextra -Wno-unused-parameter -O2 $(shell pkg-config --cflags $(PKGS))
LDLIBS += $(shell pkg-config --libs $(PKGS))
PREFIX ?= $(HOME)/.local

OBJS = main.o ui.o wttr.o

weather: $(OBJS)
	$(CC) $(OBJS) $(LDLIBS) -o $@

$(OBJS): weather.h

install: weather
	install -Dm755 weather $(PREFIX)/bin/weather

clean:
	rm -f weather $(OBJS)

.PHONY: install clean
