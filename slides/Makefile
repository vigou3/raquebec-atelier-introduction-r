### -*-Makefile-*- pour préparer les diapos de
### «Introduction à R - Atelier du colloque R à Québec 2017»
##
## Copyright (C) 2017 Vincent Goulet, David Beauchemin, Samuel Cabral Cruz
##
## 'make tex' crée les fichier .tex à partir des fichiers .Rnw avec
## Sweave.
##
## 'make pdf' fait la même chose que 'make tex' et en plus compile le
## document maître avec XeLaTeX.
##
## 'make all' est équivalent à 'make pdf'.
##
## Auteur: Vincent Goulet
##
## Ce fichier fait partie du projet «Introduction à R - Atelier du
## colloque R à Québec 2017»
## http://github.com/vigou3/raquebec-atelier-introduction-r


## Nom du document maître
MASTER = raquebec-atelier-introduction-r.pdf

## Ensemble des sources du document.
RNWFILES = \
	bases.Rnw \
	donnees.Rnw
TEXFILES = \
	couverture-avant.tex \
	frontispice.tex \
	licence.tex \
	reference.tex \
	presentation.tex \
	application.tex \
	controle.tex \
	extensions.tex \
	colophon.tex \
	couverture-arriere.tex
AUXFILES = \
	Fotolia_99831160.jpg \
	by-sa.pdf \
	by.pdf \
	sa.pdf \
	Chambers.jpg \
	introduction-programmation-r.jpg

## Outils de travail
SWEAVE = R CMD SWEAVE --encoding="utf-8"
TEXI2DVI = LATEX=xelatex texi2dvi -b
RM = rm -rf


all: pdf

.PHONY: tex pdf clean

pdf: ${MASTER}

tex: ${RNWFILES:.Rnw=.tex}

%.tex: %.Rnw
	${SWEAVE} '$<'

${MASTER}: ${MASTER:.pdf=.tex} ${RNWFILES:.Rnw=.tex} ${TEXFILES} ${AUXFILES}
	${TEXI2DVI} ${MASTER:.pdf=.tex}

clean:
	${RM} ${RNWFILES:.Rnw=.tex} \
	      *-[0-9][0-9][0-9].pdf \
	      *.aux *.log  *.blg *.bbl *.out *.rel *~ Rplots.ps


