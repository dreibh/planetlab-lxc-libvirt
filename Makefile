WEBFETCH                := wget
SHA1SUM                 := sha1sum

ALL                     += libvirt
libvirt-URL            := ftp://libvirt.org/libvirt/libvirt-0.9.9.tar.gz
libvirt-SHA1SUM        := d716303b4b00c2d8cc0ebd7e1a853e238d9723f8
libvirt                := $(notdir $(libvirt-URL))

all: $(ALL)
.PHONY: all

##############################
define download_target
$(1): $($(1))
.PHONY: $($(1))
$($(1)): 
		@if [ ! -e "$($(1))" ] ; then echo "$(WEBFETCH) $($(1)-URL)" ; $(WEBFETCH) $($(1)-URL) ; fi
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
BUILDOPTS = --without storage-disk --without storage-iscsi --without storage-scsi \
	        --without storage-fs --without storage-lvm \
	        --without polkit --without sasl --without audit --with capng --with udev \
	        --without netcf --without avahi \
	        --without xen --without qemu --without hyperv --without phyp --without esx \
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
