DOCFILE := notes.txt
TITLE := QSC 4x4 LED Matrix Design Review (v1.1)
AUTHOR := Nicholas Clark
SUBJECT := QSC Design Review
FONT := Linux Libertine O 
OUTPUT_PDF := nicholas_clark_design_review.pdf
OUTPUT_HTML := nicholas_clark_design_review.html

PANDOC := pandoc
PDFTK := pdftk
GPP := gpp
QPDF := qpdf

DEPS := filedeps.d

# This corresponds with GPP's '-H' mode, but with the
# 'quote' character disabled.
GPP_MODE := -U "<\#" ">" "\B" "|" ">" "<" ">" "\#" ""

all: pdf

.PHONY: $(DEPS) pdf all clean
.INTERMEDIATE: timestamp.md

SHELL := $(shell which bash)
KEYSTR := $(strip $(shell od --read-bytes=8 /dev/random -tx8 -An))

$(DOCFILE):
	$(eval $(if $(wildcard $@),,$(error file $@ not found)))
	@touch -c $@

include $(DEPS)
$(DEPS): $(DOCFILE)
	$(eval $(if $(wildcard $<),,$(error file $< not found)))
	@printf "$<: " > $@
	@if [ ! -e timestamp.md ]; then \
		touch timestamp.md; \
	fi
	@$(GPP) $(GPP_MODE) --includemarker "%__$(KEYSTR)__%" $< \
		| grep "__$(KEYSTR)__" \
		| sed 's/.*__$(KEYSTR)__//g' \
		| sed 's/.*__timestamp.md__//g' \
		| sort \
		| uniq \
		| grep -v "$<" \
		| tr '\n' ' ' >> $@
	@printf "\n" >> $@

pdf: $(OUTPUT_PDF)
$(OUTPUT_PDF): $(DOCFILE) default.latex header.latex
	printf "Last updated: " > timestamp.md
	printf "$$(date +'%B %d, %Y')   \n" >> timestamp.md
	printf "(commit #" >> timestamp.md
	printf "$$(git rev-list HEAD -n1 | cut -c -6 | tr '[a-z]' '[A-Z]')" >> timestamp.md
	printf ")\n\n" >> timestamp.md
	touch timestamp.md -r $<
	$(GPP) $(GPP_MODE) $< | $(PANDOC) \
	-f "markdown" \
	--filter ./mintables.py \
	--standalone \
	-o $@ \
	-V geometry:"top=1.25in, bottom=1.25in, left=1in, right=1in" \
	--latex-engine=xelatex \
	-V fontsize:11pt \
	-V mainfont:"$(FONT)" \
	-V linkcolor:black \
	--highlight-style=pygments \
	-V title:"$(TITLE)" \
	--template=./default.latex \
	-H ./header.latex
	echo "InfoKey: Title" > metadata.txt
	echo "InfoValue: $(TITLE)" >> metadata.txt
	echo "InfoKey: Author" >> metadata.txt
	echo "InfoValue: $(AUTHOR)" >> metadata.txt
	echo "InfoKey: Subject" >> metadata.txt
	echo "InfoValue: $(SUBJECT)" >> metadata.txt
	$(PDFTK) $@ update_info metadata.txt output $@.temp
	$(QPDF) $@.temp $@ --linearize --object-streams=generate --stream-data=compress
	rm metadata.txt $@.temp

html: $(OUTPUT_HTML)

$(OUTPUT_HTML): $(DOCFILE) Makefile style.css
	printf "Last updated: " > timestamp.md
	printf "$$(date +'%B %d, %Y')   \n" >> timestamp.md
	printf "(commit #" >> timestamp.md
	printf "$$(git rev-list HEAD -n1 | cut -c -6 | tr '[a-z]' '[A-Z]')" >> timestamp.md
	printf ")\n\n" >> timestamp.md
	touch timestamp.md -r $<
	$(GPP) $(GPP_MODE) $< | $(PANDOC) \
	-f "markdown" \
	--standalone \
	-c style.css \
	-o $(OUTPUT_HTML) \
	--highlight-style=pygments

clean:
	rm -f $(OUTPUT_PDF) $(OUTPUT_HTML) $(DEPS) timestamp.md metadata.txt $(OUTPUT_PDF).temp
