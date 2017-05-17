### -*-Makefile-*- pour préparer R à Québec - Atelier d'introduction à R
##
## Copyright (C) 2017 Vincent Goulet
##
## 'make pdf' crée les fichiers .tex à partir des fichiers .Rnw avec
## Sweave, place les bonnes URL vers les vidéos dans le code source et
## compile le document maître avec XeLaTeX.
##
## 'make zip' crée l'archive contenant le code source des sections
## d'exemples.
##
## 'make release' crée une nouvelle version dans GitHub, téléverse les
## fichiers PDF et .zip et modifie les liens de la page web.
##
## 'make all' est équivalent à 'make pdf' question d'éviter les
## publications accidentelles.
##
## Auteur: Vincent Goulet
##
## Ce fichier fait partie du projet R à Québec - Atelier d'introduction à R
## http://github.com/vigou3/raquebec-atelier-introduction-r


## Document maître, archive et fichier contenant les URL vers les
## vidéos explicatives dans la châine YouTube
MASTER = raquebec-atelier-introduction-r.pdf
CODE = raquebec-atelier-introduction-r-code.zip

## Numéro de version et numéro ISBN extraits du fichier maître
YEAR = $(shell grep "newcommand{\\\\year" ${MASTER:.pdf=.tex} \
	| cut -d } -f 2 | tr -d {)
VERSION = $(shell grep "newcommand{\\\\ednum" ${MASTER:.pdf=.tex} \
	| cut -d } -f 2 | tr -d {)
VERSIONSTR = $(shell grep "newcommand{\\\\edstr" ${MASTER:.pdf=.tex} \
	| cut -d } -f 2 | tr -d {)

## Le document maître dépend de tous les fichiers .tex et des fichiers
## .R mentionnés
RNWFILES = $(wildcard *.Rnw)
TEXFILES = \
	couverture-avant.tex \
	frontispice.tex \
	licence.tex \
	presentation.tex \
	colophon.tex \
	couverture-arriere.tex
RFILES = \
	presentation.R \
	bases.R

## Outils de travail
SWEAVE = R CMD SWEAVE --encoding="utf-8"
TEXI2DVI = LATEX=xelatex texi2dvi -b
RM = rm -rf

## Dépôt GitHub et authentification
REPOSURL = https://api.github.com/repos/vigou3/raquebec-atelier-introduction-r
OAUTHTOKEN = $(shell cat ~/.github/token)


all: pdf

.PHONY: tex pdf zip release create-release upload publish clean

pdf: $(MASTER)

tex: $(RNWFILES:.Rnw=.tex)

release: create-release upload publish

%.tex: %.Rnw
	$(SWEAVE) '$<'

$(MASTER): $(MASTER:.pdf=.tex) $(RNWFILES:.Rnw=.tex) $(TEXFILES) $(RFILES)
	$(TEXI2DVI) $(MASTER:.pdf=.tex)

zip: $(RFILES)
	zip -j $(CODE) ${RFILES}

create-release :
	@echo ----- Creating release on GitHub...
	if [ -e relnotes.in ]; then rm relnotes.in; fi
	touch relnotes.in
	git commit -a -m "Édition ${VERSION}" && git push
	awk 'BEGIN { ORS=" "; print "{\"tag_name\": \"edition-${VERSION}\"," } \
	      /^$$/ { next } \
	      /^## Historique/ { state=0; next } \
              (state==0) && /^### / { state=1; out=$$2; \
	                             for(i=3;i<=NF;i++){out=out" "$$i}; \
	                             printf "\"name\": \"%s\", \"body\": \"", out; \
	                             next } \
	      (state==1) && /^### / { state=2; print "\","; next } \
	      state==1 { printf "%s\\n", $$0 } \
	      END { print "\"draft\": false, \"prerelease\": false}" }' \
	      README.md >> relnotes.in
	curl --data @relnotes.in ${REPOSURL}/releases?access_token=${OAUTHTOKEN}
	rm relnotes.in
	@echo ----- Done creating the release

upload :
	@echo ----- Getting upload URL from GitHub...
	$(eval upload_url=$(shell curl -s ${REPOSURL}/releases/latest \
	 			  | awk -F '[ {]' '/^  \"upload_url\"/ \
	                                    { print substr($$4, 2, length) }'))
	@echo ${upload_url}
	@echo ----- Uploading PDF and archive to GitHub...
	curl -H 'Content-Type: application/zip' \
	     -H 'Authorization: token ${OAUTHTOKEN}' \
	     --upload-file ${MASTER} \
             -i "${upload_url}?&name=${MASTER}" \
	     --upload-file ${CODE} \
             -i "${upload_url}?&name=${CODE}" -s
	@echo ----- Done uploading files

publish :
	@echo ----- Publishing the web page...
	cd docs && \
	sed -e 's/<VERSION>/${VERSION}/g' \
	    -e 's/<VERSIONSTR>/${VERSIONSTR}/' \
	    -e 's/<ISBN>/${ISBN}/' \
	    index.md.in > index.md && \
	sed -e 's/<VERSION>/${VERSION}/g' \
	    -e 's/<MASTER>/${MASTER}/' \
	    _layouts/default.html.in > _layouts/default.html
	git commit -a -m "Mise à jour de la page web pour l'édition ${VERSION}" && \
	git push
	@echo ----- Done publishing

clean:
	$(RM) $(RNWFILES:.Rnw=.tex) \
	      *-[0-9][0-9][0-9].pdf \
	      *.aux *.log  *.blg *.bbl *.out *.rel *~ Rplots.ps


