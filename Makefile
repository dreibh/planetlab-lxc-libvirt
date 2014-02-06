WEBFETCH                := wget
SHA1SUM                 := sha1sum

# tried to download this on the fly using git archive at git://libvirt.org/libvirt.git
# but it feels like git archive is not supported/allowed there
ALL                     += libvirt
libvirt-URL            := http://libvirt.org/sources/libvirt-1.2.1.tar.gz
libvirt-SHA1SUM        := ea8e237e0df9f1828ff4a7a649c42aa45af7ecd7
libvirt                := $(notdir $(libvirt-URL))

all: $(ALL)
.PHONY: all

##############################
define download_target
$(1): $($(1))
.PHONY: $(1)
$($(1)): 
	@if [ ! -e "$($(1))" ] ; then \
	{ echo Using primary; echo "$(WEBFETCH) $($(1)-URL)" ; $(WEBFETCH) $($(1)-URL1) ; } ; fi
	@if [ ! -e "$($(1))" ] ; then echo "Could not download source file: $($(1)) does not exist" ; exit 1 ; fi
	@if test "$$$$($(SHA1SUM) $($(1)) | awk '{print $$$$1}')" != "$($(1)-SHA1SUM)" ; then \
	    echo "sha1sum of the downloaded $($(1)) does not match the one from 'Makefile'" ; \
	    echo "Local copy: $$$$($(SHA1SUM) $($(1)))" ; \
	    echo "In Makefile: $($(1)-SHA1SUM)" ; \
	    false ; \
	else \
	    ls -l $($(1)) ; \
	fi
endef

$(eval $(call download_target,libvirt))

sources: $(ALL) 
.PHONY: sources

####################
# default - overridden by the build
SPECFILE = libvirt.spec

PWD=$(shell pwd)
PREPARCH ?= noarch
RPMDIRDEFS = --define "_sourcedir $(PWD)" --define "_builddir $(PWD)" --define "_srcrpmdir $(PWD)" --define "_rpmdir $(PWD)"
BUILDOPTS = --without xen --without qemu --without hyperv --without phyp --without esx \
			--without netcf --without avahi --without polkit --without sasl --without audit \
			--without storage-iscsi --without storage-scsi --without storage-disk \
			--without storage-rbd --without selinux --without dtrace --without sanlock \
			--without libxl --without vbox --with capng --with udev --with interface \
			--define 'packager PlanetLab'

trees: sources
	rpmbuild $(RPMDIRDEFS) $(RPMDEFS) --nodeps -bp --target $(PREPARCH) $(SPECFILE)

srpm: sources
	rpmbuild $(RPMDIRDEFS) $(RPMDEFS) --nodeps -bs $(SPECFILE)

TARGET ?= $(shell uname -m)
rpm: sources
	rpmbuild $(RPMDIRDEFS) $(RPMDEFS) --nodeps --target $(TARGET) $(BUILDOPTS) -bb $(SPECFILE)

clean:
	rm -f *.rpm *.tgz *.bz2 *.gz

++%: varname=$(subst +,,$@)
++%:
		@echo "$(varname)=$($(varname))"
+%: varname=$(subst +,,$@)
+%:
		@echo "$($(varname))"

