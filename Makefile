### -*-Makefile-*- pour préparer «Introduction à R - Atelier du colloque R à Québec 2017»
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
## Ce fichier fait partie du projet «Introduction à R - Atelier du
## colloque R à Québec 2017»
## http://github.com/vigou3/raquebec-atelier-introduction-r


## Noms du document maître et de l'archive
SLIDES = slides/raquebec-atelier-introduction-r.pdf
CASESTUDY = 
ARCHIVE = raquebec-atelier-introduction-r.zip

## Numéro de version
VERSION = 0.9

## Ensemble des sources du document.
SCRIPTS = \
	scripts/presentation.R \
	scripts/bases.R \
	scripts/donnees.R \
	scripts/application.R \
	scripts/controle.R \
	scripts/extensions.R
DATA = \
	data/AirportModif.csv \
	data/benchmark.csv \
	data/province.csv

## Outils de travail
SWEAVE = R CMD SWEAVE --encoding="utf-8"
TEXI2DVI = LATEX=xelatex texi2dvi -b
RM = rm -rf

## Dépôt GitHub et authentification
REPOSURL = https://api.github.com/repos/vigou3/raquebec-atelier-introduction-r
OAUTHTOKEN = ${shell cat ~/.github/token}


all: doc

.PHONY: tex pdf zip release create-release upload publish clean

release: create-release upload publish

${SLIDES}:
	${MAKE} -C $(dir ${SLIDES})

zip: ${SLIDES} ${SCRIPTS} ${DATA}
	zip -j --filesync ${ARCHIVE} README.md ${SLIDES} ${SCRIPTS} ${DATA} 

create-release :
	@echo ----- Creating release on GitHub...
	if [ -e relnotes.in ]; then rm relnotes.in; fi
	touch relnotes.in
	# git commit -a -m "Version ${VERSION}" && git push
	awk 'BEGIN { ORS=" "; print "{\"tag_name\": \"v${VERSION}\"," } \
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
	# curl --data @relnotes.in ${REPOSURL}/releases?access_token=${OAUTHTOKEN}
	# rm relnotes.in
	@echo ----- Done creating the release

upload :
	@echo ----- Getting upload URL from GitHub...
	$(eval upload_url=$(shell curl -s ${REPOSURL}/releases/latest \
	 			  | awk -F '[ {]' '/^  \"upload_url\"/ \
	                                    { print substr($$4, 2, length) }'))
	@echo ${upload_url}
	@echo ----- Uploading PDF and archive to GitHub...
	# curl -H 'Content-Type: application/zip' \
	#      -H 'Authorization: token ${OAUTHTOKEN}' \
	#      --upload-file ${MASTER} \
        #      -i "${upload_url}?&name=${MASTER}" \
	#      --upload-file ${CODE} \
        #      -i "${upload_url}?&name=${CODE}" -s
	@echo ----- Done uploading files

publish :
	@echo ----- Publishing the web page...
	cd docs && \
	sed -e 's/<VERSION>/${VERSION}/g' \
	    -e 's/<ARCHIVE>/${ARCHIVE}/' \
	    index.md.in > index.md && \
	sed -e 's/<VERSION>/${VERSION}/g' \
	    -e 's/<ARCHIVE>/${ARCHIVE}/' \
	    _layouts/default.html.in > _layouts/default.html
	# git commit -a -m "Mise à jour de la page web pour l'édition ${VERSION}" && \
	# git push
	@echo ----- Done publishing

clean:
	${RM} ${RNWFILES:.Rnw=.tex} \
	      *-[0-9][0-9][0-9].pdf \
	      *.aux *.log  *.blg *.bbl *.out *.rel *~ Rplots.ps


