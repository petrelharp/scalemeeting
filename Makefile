.PHONY : clean publish setup htmls display 

SHELL = /bin/bash

###
# names of files you want made and published to github (in gh-pages) should be in html-these-files.mk
# which lives in the master branch and is automatically pushed over
include config.mk

PANDOC_HTML_OPTS = -c resources/pandoc.css --mathjax=https:////cdn.mathjax.org/mathjax/latest/MathJax.js?config=TeX-AMS-MML_HTMLorMML

MD_HTML = $(patsubst %.md,$(DISPLAYDIR)/%.html,$(MDFILES))
TEX_HTML = $(patsubst %.tex,$(DISPLAYDIR)/%.html,$(TEXFILES))
HTMLS = $(MD_HTML) $(TEX_HTML)

# hope their head isn't detached
GITBRANCH := $(shell git symbolic-ref -q --short HEAD)

# this re-makes everything.  if this is too onerous, delete 'clean' here.
# but beware, cruft will start to build up.
display : clean
	make $(HTMLS)
	# don't want to overwrite index.html if it is already there
	find display -maxdepth 1 -name "index.html" | grep -q . || make skelml.index

htmls :
	make $(HTMLS)


# update html in the gh-pages branch
#   add e.g. 'pdfs' to the next line to also make pdfs available there
publish : display
	git checkout gh-pages
	@echo "removing -- $$(grep -vxF -f <(echo .gitignore; find display/ -type f | sed -e 's_^display/__') <(git ls-files) | tr '\n' ' ')"
	# remove files no longer in display
	OLDFILES=$$(grep -vxF -f  <(echo .gitignore; find display/ -type f | sed -e 's_^display/__') <(git ls-files)); \
			 if [ ! -z "$$OLDFILES" ]; then git rm $$OLDFILES; fi
	# and add updated or new ones
	@echo "adding -- $$(find display/ -type f | sed -e 's_^display/__' | tr '\n' ' ')"
	cp -r display/* .
	UPFILES=$$(find display/ -type f | sed -e 's_^display/__'); \
		if [ ! -z "$$UPFILES" ]; then git add $$UPFILES; fi
	git commit -a -m 'automatic update of html'
	git checkout $(GITBRANCH)

# set up a clean gh-pages branch
setup : 
	@if ! git diff-index --quiet HEAD --; then echo "Commit changes first."; exit 1; fi
	-mkdir display
	git checkout --orphan gh-pages
	-rm $(shell git ls-files -c)
	git rm --cached $(shell git ls-files --cached)
	echo "display/" >> .gitignore
	-git add .gitignore
	git commit -m 'initialized gh-pages branch'
	git checkout $(GITBRANCH)

clean : 
	-rm -f $(shell git ls-files --other display/*)
	-rm -f *.aux *.log *.bbl *.blg *.out *.toc *.nav *.snm *.vrb texput.* LaTeXML.cache
	-cd display; rm -f *.aux *.log *.bbl *.blg *.out *.toc *.nav *.snm *.vrb texput.* LaTeXML.cache



$(DISPLAYDIR)/%.html : %.md
	mkdir -p $(DISPLAYDIR)/resources
	cp resources/pandoc.css $(DISPLAYDIR)/resources
	pandoc $(PANDOC_HTML_OPTS) -f markdown -o $@ $<


## 
# Graphics whatnot

# save inkscape svg files as .ink.svg and this'll do the right thing
$(DISPLAYDIR)/%.svg : %.ink.svg
	inkscape $< --export-plain-svg=$@

$(DISPLAYDIR)/%.pdf : %.ink.svg
	inkscape $< --export-pdf=$@

$(DISPLAYDIR)/%.svg : %.pdf
	inkscape $< --export-plain-svg=$@

$(DISPLAYDIR)/%.png : %.pdf
	convert -density 300 $< -flatten $@
