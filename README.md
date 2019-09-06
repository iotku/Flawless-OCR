# Flawless-OCR
Bash Script intending to provide OCR in a fast mannor without quality loss

# WARNING: This is a brand new script and a work in progress

# Known Issues
* pdfcrop is not optional (may turn out fine, but will likely modify margins) https://github.com/iotku/Flawless-OCR/issues/1
* Bookmarks aren't maintained and will probably disappear https://github.com/iotku/Flawless-OCR/issues/2
* Minor typos in comments are expected and some comments may be out of date 

# Requirements
	- ghostscript
	- tesseract
	- pdfmerge.py (python3) (by Georg Sauthoff :: https://raw.githubusercontent.com/gsauthof/utility/master/pdfmerge.py)
	- pdfcrop (from texlive-extra-utils)
	- pdfinfo
	- xargs
