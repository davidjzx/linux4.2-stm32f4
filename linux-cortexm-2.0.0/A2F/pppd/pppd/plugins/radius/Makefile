# Makefile for RADIUS plugin
#
# Copyright 2002 Roaring Penguin Software Inc.
#

DESTDIR = $(INSTROOT)/usr
MANDIR = $(DESTDIR)/share/man/man8
LIBDIR = $(DESTDIR)/lib/pppd/$(VERSION)

VERSION = $(shell awk -F '"' '/VERSION/ { print $$2; }' ../../patchlevel.h)

INSTALL	= install

ifeq ($(CONFIG_USER_PPPD_WITH_DYNAMIC_PLUGINS),y)
PLUGIN = radius.so radattr.so radrealms.so
CFLAGS += -fPIC
else
PLUGIN = libradius.o
endif

CFLAGS += -I. -I../.. -I../../../include -DRC_LOG_FACILITY=LOG_DAEMON

# Uncomment the next line to include support for Microsoft's
# MS-CHAP authentication protocol.
CHAPMS=y
# Uncomment the next line to include support for MPPE.
ifeq ($(CONFIG_USER_PPPD_WITH_MPPE),y)                                                                                  
MPPE=y                                                                                                                  
endif                                                                                                                   
# Uncomment the next lint to include support for traffic limiting
MAXOCTETS=y

ifdef CHAPMS
CFLAGS += -DCHAPMS=1
ifdef MPPE
CFLAGS += -DMPPE=1
endif
endif
ifdef MAXOCTETS
CFLAGS += -DMAXOCTETS=1
endif

all: $(PLUGIN)

install: all
	$(INSTALL) -d -m 755 $(LIBDIR)
	$(INSTALL) -s -c -m 755 radius.so $(LIBDIR)
	$(INSTALL) -s -c -m 755 radattr.so $(LIBDIR)
	$(INSTALL) -s -c -m 755 radrealms.so $(LIBDIR)
	$(INSTALL) -c -m 444 pppd-radius.8 $(MANDIR)
	$(INSTALL) -c -m 444 pppd-radattr.8 $(MANDIR)

radius.so: radius.o libradiusclient.a
	$(CC) -o radius.so -shared radius.o libradiusclient.a

radattr.so: radattr.o
	$(CC) -o radattr.so -shared radattr.o

radrealms.so: radrealms.o
	$(CC) -o radrealms.so -shared radrealms.o

CLIENTOBJS = avpair.o buildreq.o config.o dict.o ip_util.o \
	clientid.o sendserver.o lock.o util.o md5.o

libradiusclient.a: $(CLIENTOBJS)
	$(AR) rv $@ $?

libradius.o: radius.o $(CLIENTOBJS)
	$(LD) -r -o $@ $^

libradattr.a: radattr.o
	$(AR) rv $@ $?

libradrealms.a: radrealms.o
	$(AR) rv $@ $?

clean:
	rm -f *.o *.so *.a

distclean:
	rm -f *.o *.so *.a

dist-clean: distclean
