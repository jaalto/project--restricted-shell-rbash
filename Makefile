#
#   Copyright information
#
#	Copyright (C) 2011-2012 Jari Aalto
#
#   License
#
#	This program is free software; you can redistribute it and/or modify
#	it under the terms of the GNU General Public License as published by
#	the Free Software Foundation; either version 2 of the License, or
#	(at your option) any later version.
#
#	This program is distributed in the hope that it will be useful,
#	but WITHOUT ANY WARRANTY; without even the implied warranty of
#	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
#	GNU General Public License for more details.
#
#	You should have received a copy of the GNU General Public License
#	along with this program. If not, see <http://www.gnu.org/licenses/>.

ifneq (,)
This makefile requires GNU Make.
endif

PACKAGE		= restricted-shell-rbash
NAME		= restricted-shell-create
BIN		= $(NAME).sh
PACKAGE_DOC	= $(PACKAGE)
# The real binary
LIBPRG		= makefile.sh

DESTDIR		=
prefix		= /usr
exec_prefix	= $(prefix)
man_prefix	= $(prefix)/share
mandir		= $(man_prefix)/man
bindir		= $(exec_prefix)/bin
sbindir		= $(exec_prefix)/sbin
sharedir	= $(prefix)/share

BINDIR		= $(DESTDIR)$(sbindir)
DOCDIR		= $(DESTDIR)$(sharedir)/doc/$(PACKAGE_DOC)
EXAMPLESDIR	= $(DOCDIR)/examples
LOCALEDIR	= $(DESTDIR)$(sharedir)/locale
SHAREDIR	= $(DESTDIR)$(sharedir)/$(PACKAGE)
LIBDIR		= $(DESTDIR)$(prefix)/lib/$(PACKAGE)
SBINDIR		= $(DESTDIR)$(exec_prefix)/sbin
ETCDIR		= $(DESTDIR)/etc/$(PACKAGE)

# 1 = regular, 5 = conf, 6 = games, 8 = daemons
MANDIR		= $(DESTDIR)$(mandir)
MANDIR1		= $(MANDIR)/man1
MANDIR5		= $(MANDIR)/man5
MANDIR6		= $(MANDIR)/man6
MANDIR8		= $(MANDIR)/man8

PERL		= perl
TAR		= tar
TAR_OPT_NO	= --exclude='.build'	\
		  --exclude='.sinst'	\
		  --exclude='.inst'	\
		  --exclude='tmp'	\
		  --exclude='*.bak'	\
		  --exclude='*[~\#]'	\
		  --exclude='.\#*'	\
		  --exclude='CVS'	\
		  --exclude='.svn'	\
		  --exclude='.git'	\
		  --exclude='.bzr'	\
		  --exclude='*.tar*'	\
		  --exclude='*.tgz'	\
		  --exclude='Makefile'

INSTALL		= /usr/bin/install
INSTALL_BIN	= $(INSTALL) -m 755
INSTALL_DATA	= $(INSTALL) -m 644
INSTALL_SUID	= $(INSTALL) -m 4755

DIST_DIR	= ../build-area
DATE		= `date +"%Y.%m%d"`
VERSION		= $(DATE)
RELEASE		= $(PACKAGE)-$(VERSION)

INSTALL_OBJS_LIB = README.rst makefile.sh .bash* .ssh/*
INSTALL_OBJS_BIN = bin/$(BIN)
INSTALL_OBJS_DOC = ChangeLog
INSTALL_OBJS_MAN = bin/*.1

all:
	@echo "Nothing to compile."
	@echo "Try 'make help' or 'make -n DESTDIR= prefix=/usr/local install'"

# Rule: help - display Makefile rules
help:
	grep "^# Rule:" Makefile | sort

# Rule: clean - remove temporary files
clean:
	# clean
	rm -rf tmp
	find . -type f \
		-name "*[#~]" \
		-o -name "*.\#*" \
		-o -name "*.x~*" \
		-o -name "pod*.tmp" \
		-o -name "*.1" \
	| xargs --no-run-if-empty rm

distclean: clean

realclean: clean

# Rule: dist-git - [maintainer] release from Git repository
dist-git: test
	rm -f $(DIST_DIR)/$(RELEASE)*

	git archive --format=tar --prefix=$(RELEASE)/ master | \
	gzip --best > $(DIST_DIR)/$(RELEASE).tar.gz

	chmod 644 $(DIST_DIR)/$(RELEASE).tar.gz

	tar -tvf $(DIST_DIR)/$(RELEASE).tar.gz | sort -k 5
	ls -la $(DIST_DIR)/$(RELEASE).tar.gz

# The "gt" is maintainer's program frontend to Git
# Rule: dist-snap - [maintainer] release snapshot from Git repository
dist-snap: test
	@echo gt tar -q -z -p $(PACKAGE) -c -D master

# Rule: dist - [maintainer] alias for dist-git
dist: dist-git

# Rule: dist-ls - [maintainer] list of release files
dist-ls:
	@ls -1tr $(DIST_DIR)/$(NAME)*

# Rule: ls - [maintainer] alias for dist-ls
ls: dist-ls

bin/$(NAME).1: bin/$(NAME).1.pod
	make -f pod2man.mk PACKAGE=bin/$(NAME) makeman
	@-rm -f *.x~~ pod*.tmp

doc/manual/index.html: bin/$(NAME).1.pod
	pod2html $< > $@
	@-rm -f *.x~~ pod*.tmp

doc/manual/index.txt: bin/$(NAME).1.pod
	pod2text $< > $@
	@-rm -f *.x~~ pod*.tmp

# Rule: man - Generate or update manual page
man: bin/$(NAME).1

html: doc/manual/index.html

txt: doc/manual/index.txt

# Rule: doc - Generate or update all documentation
doc: man html txt

# Rule: pod-test - Check POD syntax
pod-test:
	# pod-test - Check POD syntax
	podchecker bin/*.pod

# Rule: test - Run tests
test: pod-test

install-doc:
	# install-doc - Install documentation
	$(INSTALL_BIN) -d $(DOCDIR)

	[ ! "$(INSTALL_OBJS_DOC)" ] || \
		$(INSTALL_DATA) $(INSTALL_OBJS_DOC) $(DOCDIR)

	$(TAR) -C doc $(TAR_OPT_NO) --create --file=- . | \
	$(TAR) -C $(DOCDIR) --extract --file=-

install-man: man
	# install-man - Install manual pages
	$(INSTALL_BIN) -d $(MANDIR1)
	$(INSTALL_DATA) $(INSTALL_OBJS_MAN) $(MANDIR1)

install-lib:
	# install-lib - Install libraries
	$(INSTALL_BIN) -d $(SHAREDIR)
	for f in $(INSTALL_OBJS_LIB); \
	do \
		$(INSTALL_DATA) -D $$f $(SHAREDIR)/$$f; \
	done
	chmod 755 $(SHAREDIR)/*.sh

install-bin:
	# install-bin - Install programs
	$(INSTALL_BIN) -d $(BINDIR)
	for f in $(INSTALL_OBJS_BIN); \
	do \
		dest=$$(basename $$f | sed -e 's,.*/,,' -e 's,[.]sh,,' ); \
		$(INSTALL_BIN) $$f $(BINDIR)/$$dest; \
	done
	# Update path
	sed --in-place \
		-e "s,%PROGRAM,$(LIBDIR)/$(LIBPRG)," \
		-e "s,$(DESTDIR),," \
		$(BINDIR)/$(NAME)

# Rule: install - Standard install
install: install-bin install-lib install-man install-doc

# Rule: install-test - [maintainer] run test installation to tmp/
install-test:
	rm -rf tmp
	make DESTDIR=`pwd`/tmp prefix=/usr install
	find tmp | sort

.PHONY: clean distclean realclean
.PHONY: install install-bin install-lib install-man
.PHONY: all man doc test install-test pod-test
.PHONY: dist dist-git dist-ls ls

# End of file
