
TMP = $(CURDIR)/tmp
VERSION = $(shell grep ^Version python-nitrate.spec | sed 's/.* //')

# Push files to the production web only when in the master branch
ifeq "$(shell git rev-parse --abbrev-ref HEAD)" "master"
PUSH_URL = fedorapeople.org:public_html/python-nitrate
else
PUSH_URL = fedorapeople.org:public_html/python-nitrate/testing
endif

PACKAGE = python-nitrate-$(VERSION)
DOCS = $(TMP)/$(PACKAGE)/docs
EXAMPLES = $(TMP)/$(PACKAGE)/examples
CSS = --stylesheet=style.css --link-stylesheet
FILES = LICENSE README.rst \
		Makefile python-nitrate.spec setup.py \
		docs examples source

all: push clean

build:
	mkdir -p $(TMP)/{SOURCES,$(PACKAGE)}
	cp -a $(FILES) $(TMP)/$(PACKAGE)
	rst2man README.rst | gzip > $(DOCS)/python-nitrate.1.gz
	rst2html README.rst $(CSS) > $(DOCS)/index.html
	rst2man $(DOCS)/notes.rst | gzip > $(DOCS)/nitrate-notes.1.gz
	rst2html $(DOCS)/notes.rst $(CSS) > $(DOCS)/notes.html
	rst2man $(DOCS)/nitrate.rst | gzip > $(DOCS)/nitrate.1.gz
	rst2html $(DOCS)/nitrate.rst $(CSS) > $(DOCS)/nitrate.html

tarball: build
	cd $(TMP) && tar cfj SOURCES/$(PACKAGE).tar.bz2 $(PACKAGE)
	@echo ./tmp/SOURCES/$(PACKAGE).tar.bz2

version:
	@echo "$(VERSION)"

rpm: tarball
	rpmbuild --define '_topdir $(TMP)' -bb python-nitrate.spec

srpm: tarball
	rpmbuild --define '_topdir $(TMP)' -bs python-nitrate.spec

packages: rpm srpm

# Python packaging
wheel:
	python setup.py bdist_wheel
upload: wheel
	twine upload dist/*.whl

push: packages
	# Documentation
	scp $(DOCS)/*.{css,html} $(PUSH_URL)
	# Examples
	scp $(EXAMPLES)/*.py $(PUSH_URL)/examples
	# Archives & rpms
	scp python-nitrate.spec \
		$(TMP)/SRPMS/$(PACKAGE)* \
		$(TMP)/RPMS/noarch/$(PACKAGE)* \
		$(TMP)/SOURCES/$(PACKAGE).tar.bz2 \
		$(PUSH_URL)/download

clean:
	rm -rf $(TMP) build dist nitrate.egg-info source/*.pyc source/__pycache__
