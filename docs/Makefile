### -*-Makefile-*- pour mettre à jours la page web de
### «Introduction à R - Atelier du colloque R à Québec 2017»
##
## Copyright (C) 2017 Vincent Goulet
##
## Auteur: Vincent Goulet
##
## Ce fichier fait partie du projet «Introduction à R - Atelier du
## colloque R à Québec 2017»
## http://github.com/vigou3/raquebec-atelier-introduction-r


## Numéro de version
VERSION = $(shell cat ../VERSION)

update-pages:
	awk 'BEGIN { FS = "/"; OFS = "/" } \
	     /^## Version/ { print; getline; print; getline; \
	                     gsub(/[0-9]+\.[0-9]+/, "${VERSION}") } \
	     /\[documentation\]/ { $$3 = "v${VERSION}" } 1' \
	    index.md > tmpfile && \
	  mv tmpfile index.md
	cd _layouts && \
	  awk 'BEGIN { FS = "/"; OFS = "/" } \
	       /{{ site.github.releases_url }}/ { $$3 = "v${VERSION}" } 1' \
	       default.html > tmpfile && \
	  mv tmpfile default.html
	# git commit -a -m "Mise à jour de la page web pour l'édition ${VERSION}" && \
	# git push
	@echo ----- Done publishing


