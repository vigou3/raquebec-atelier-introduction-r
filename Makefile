### -*-Makefile-*- pour préparer «Introduction à R - Atelier du colloque R à Québec 2017»
##
## Copyright (C) 2017 Vincent Goulet
##
## 'make doc' crée la documentation.
##
## 'make zip' crée l'archive contenant le matériel de la formation.
##
## 'make release' crée une nouvelle version dans GitHub, téléverse le
## .zip et modifie les liens de la page web.
##
## 'make all' est équivalent à 'make doc zip' question d'éviter les
## publications accidentelles.
##
## Auteur: Vincent Goulet
##
## Ce fichier fait partie du projet «Introduction à R - Atelier du
## colloque R à Québec 2017»
## http://github.com/vigou3/raquebec-atelier-introduction-r


## Nom de l'archive
ARCHIVE = raquebec-atelier-introduction-r.zip

## Nom du répertoire temporaire pour la construction de l'archive
TMPDIR = tmpdir

## Numéro de version
VERSION = $(shell cat VERSION)

## Composantes de l'archive
README = README.md
SLIDES = slides/raquebec-atelier-introduction-r.pdf
CASESTUDY = caseStudy/Statement/LaTeX/OpenFlightsCaseStudy.pdf
SCRIPTS = \
	scripts/presentation.R \
	scripts/bases.R \
	scripts/donnees.R \
	scripts/application.R \
	scripts/controle.R \
	scripts/extensions.R \
	scripts/etude.R \
	scripts/etude-solutions.R
DATA = \
	data/AirportModif.csv \
	data/benchmark.csv \
	data/province.csv

## Dépôt GitHub et authentification
REPOSURL = https://api.github.com/repos/vigou3/raquebec-atelier-introduction-r
OAUTHTOKEN = ${shell cat ~/.github/token}

# Outils de travail
RM = rm -r


all: doc zip

.PHONY: tex pdf zip release create-release upload publish clean

release: create-release upload publish

doc:
	${MAKE} -C $(dir ${SLIDES})

zip: ${SLIDES} ${CASESTUDY} ${SCRIPTS} ${DATA} ${README}
	if [ -d ${TMPDIR} ]; then ${RM} ${TMPDIR}; fi
	mkdir -p ${TMPDIR} ${TMPDIR}/data
	touch ${TMPDIR}/${README} && \
	  awk 'state==0 && /^# / { state=1 }; \
	       /^## Auteurs/ { printf("## Version\n\n%s\n\n", "${VERSION}") } \
	       state' ${README} >> ${TMPDIR}/${README}
	cp ${SLIDES} ${CASESTUDY} ${SCRIPTS} ${TMPDIR}
	cp ${DATA} ${TMPDIR}/data
	cd ${TMPDIR} && zip --filesync -r ../${ARCHIVE} *
	${RM} ${TMPDIR}

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
	      ${README} >> relnotes.in
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
	     --upload-file ${ARCHIVE} \
             -i "${upload_url}?&name=${ARCHIVE}" -s
	@echo ----- Done uploading files

publish :
	@echo ----- Publishing the web page...
	${MAKE} -C docs
	@echo ----- Done publishing

clean:
	${RM} ${RNWFILES:.Rnw=.tex} \
	      *-[0-9][0-9][0-9].pdf \
	      *.aux *.log  *.blg *.bbl *.out *.rel *~ Rplots.ps


