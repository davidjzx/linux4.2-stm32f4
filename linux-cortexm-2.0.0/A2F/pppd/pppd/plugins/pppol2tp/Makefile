#CC	= gcc
#COPTS	= -O2 -g
CFLAGS	+= $(COPTS) -I. -I../.. -I../../../include
INSTALL	= install

ifeq ($(CONFIG_USER_PPPD_WITH_DYNAMIC_PLUGINS),y)
CFLAGS  += -fPIC -DDYNAMIC_PLUGINS=1
LDFLAGS = -shared
SO = so
PLUGINS := pppol2tp.so openl2tp.so
else
PLUGINS := libpppol2tp.o
SO = o
endif

#***********************************************************************

DESTDIR = /usr
LIBDIR = $(DESTDIR)/lib/pppd/$(VERSION)

VERSION = $(shell awk -F '"' '/VERSION/ { print $$2; }' ../../patchlevel.h)

all: $(PLUGINS)

%.so: %.o
	$(CC) $(CFLAGS) -o $@ -shared $^ $(LIBS)

libpppol2tp.o: pppol2tp.o openl2tp.o
	$(CC) $(CFLAGS) -c -o $@ $^

install: all
	$(INSTALL) -d -m 755 $(LIBDIR)
	$(INSTALL) -c -m 4550 $(PLUGINS) $(LIBDIR)

clean:
	rm -f *.o *.so

%.o: %.c
	$(CC) $(CFLAGS) -c -o $@ $<
