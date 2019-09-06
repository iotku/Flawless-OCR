# Flawless-OCR
Bash Script intending to provide OCR in a fast mannor without quality loss

# WARNING: This is a brand new script and a work in progress

# Known Issues
* pdfcrop is not optional (may turn out fine, but will likely modify margins) https://github.com/iotku/Flawless-OCR/issues/1'
** It's also really slow!
* Bookmarks aren't maintained and will probably disappear https://github.com/iotku/Flawless-OCR/issues/2
* Minor typos in comments are expected and some comments may be out of date 

# Requirements
	- ghostscript
	- tesseract
	- pdfmerge.py (python3) (by Georg Sauthoff :: https://raw.githubusercontent.com/gsauthof/utility/master/pdfmerge.py)
	- pdfcrop (from texlive-extra-utils)
	- pdfinfo
	- xargs

# Why use this script?
* Runs tesseract OCR in Parallel on all processors (Gotta go fast!)
* All external depdenancies used don't have insane memory requirements (Works well even on Large PDFs, tested with >1000 page PDF)
* Aims to maintain quality with some workarounds as tesseract damages PDF image quality if run by itself.
* pdfcrop (soon to be optional) can remove annoying margins as some PDFs have a lot of dead space
