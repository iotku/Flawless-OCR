# Flawless-OCR
Bash Script intending to provide OCR in a fast mannor without quality loss

# WARNING: This is a brand new script and a work in progress
A well established program that appears to have the same goals (or higher) than this is OCRmyPDF https://github.com/jbarlow83/OCRmyPDF/
It is very robust and not terribly much slower. (and in some senarios may be faster while producing lower filesizes)
    
# Usage
- pdfscan.sh [input.pdf] [output.pdf]

# Known Issues
* Bookmarks aren't maintained and will probably disappear https://github.com/iotku/Flawless-OCR/issues/2
* Minor typos in comments are expected and some comments may be out of date 

# Requirements
- ghostscript
- tesseract-ocr
- pdfmerge.py (python3) (by Georg Sauthoff :: https://raw.githubusercontent.com/gsauthof/utility/master/pdfmerge.py)
- pdfcrop (from texlive-extra-utils)
- pdfinfo
- xargs

# Why use this script?
* Runs tesseract OCR in Parallel on all processor threads (Gotta go fast!)
* All external depdenancies used don't have insane memory requirements (Works well even on Large PDFs, tested with >1000 page PDF)
* Aims to maintain quality with some workarounds as tesseract damages PDF image quality if run by itself.
