pdf:
		pdflatex report.tex
		pdflatex report.tex
		pdflatex report.tex

clean:
		find . -maxdepth 2 -name '*.log' -exec rm {} \;
		find . -maxdepth 2 -name '*.aux' -exec rm {} \;
		find . -maxdepth 2 -name '*.toc' -exec rm {} \;
		find . -maxdepth 2 -name '*.lof' -exec rm {} \;
		find . -maxdepth 2 -name '*.lot' -exec rm {} \;
		find . -maxdepth 2 -name '*.out' -exec rm {} \;
		find . -maxdepth 2 -name '*.bbl' -exec rm {} \;
		find . -maxdepth 2 -name '*.blg' -exec rm {} \;
		rm -f report.pdf