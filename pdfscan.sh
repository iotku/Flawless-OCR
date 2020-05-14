#!/bin/bash
set -euf -o pipefail
ORIGPDF="$1"
OUTPDF="$2"
VERSION=0.1.0
# Requirements
#	- ghostscript
#	- tesseract-ocr
#       - PyPDF2 (python module)
#	- pdfmerge.py (by Georg Sauthoff :: https://raw.githubusercontent.com/gsauthof/utility/master/pdfmerge.py )
# 	- pdfcrop (from texlive-extra-utils)
#	- pdfinfo
#	- xargs

# Bugs: Doesn't maintain bookmarks

function showHelp () {
# Put reasonable help display here...
	printf "pdfscan by iotku\n"
	printf "Version %s \n" "$VERSION"
	printf "Usage:"
	printf "\n\t%s [--option] input.pdf output.pdf\n" "$0"
	printf "Options:"
	printf "\n\t--autocrop"
}

AUTOCROP="false"
function runCropPDF () {
	# Crop to A4 with 20 (pixels?) margins
	# Requires: texlive-extra-utils
	printf "[pdfcrop] start\n"
	pdfcrop --verbose --papersize a4 --margins "20 20 20 20" "$ORIGPDF" "${TMPPREFIX}.pdf"
	printf "[pdfcrop] done.\n"
	CROPPDF="${TMPPREFIX}.pdf"
}

function genSplitCMDS (){
    # If expr returns negative value it will return 1 which will kill script
	if [ "$PAGES" -lt "$CPUS" ]; then
		SPLITBY=1
	else
		SPLITBY=$(expr "$PAGES" / "$CPUS")
	fi

	SPLITCOUNT=0
	for (( i = 1; i <= "$PAGES"; i += $(expr "$SPLITBY" + 1) ))
	do
	SPLITCOUNT=$((SPLITCOUNT+=1))
	# Convert to tiff (for input to tesseract ocr), because we're merging into the original PDF quality/color doesn't matter much as long as the resolution is appropriate for OCR
	if [ $(expr "$i" + "$SPLITBY") -gt $PAGES ]; then
		ENDPAGE=$PAGES
	else
		ENDPAGE=$(expr "$i" + "$SPLITBY")
	fi

	# Consider using a different DEVICE if it may improve OCR (Testing required)
	printf 'gs -o "%s_%s.tiff" -dFirstPage="%s" -dLastPage="%s" -sDEVICE=tiffgray -sCompression=lzw -r300 %q\n' "$TMPPREFIX" "$SPLITCOUNT" "$i" "$ENDPAGE" "$CROPPDF" # Find faster method? -r300 is 300 DPI which should be suitable for OCR
	done
}

function main () {
	TMPPREFIX=$(mktemp --suffix=pdfscan -p .) # Dry run should produce name without creating redundant file, but man page calls it unsafe for whatever reason...
	CPUS=$(getconf _NPROCESSORS_ONLN)
	CROPPDF="$ORIGPDF"

	# runCropPDF # Should be run *AFTER* CROPPDF is declared in main because it overwrites variable
	PAGES=$(pdfinfo "$CROPPDF" | grep -a Pages | awk '{print $2}')

	genSplitCMDS | sed 's/.*/"&"/' | xargs -I '{}' -P $CPUS bash -c '{}'

	# Tesseract pdf generation is NOT lossless and produces artifacts compared to the original PDF
	# argument -c textonly_pdf=1 would produce image-less pdf (making gs -dFILTERIMAGE irrelevant), but alignment/width seems off
	# Thus we will strip images later before merging into a pdf
	printf "[tesseract] Starting OCR\n"
	export OMP_THREAD_LIMIT=1 # Be sure to Only use one thread per tesseract instance
	find . -wholename "${TMPPREFIX}*.tiff" | sed 's/.*/"&"/' | xargs -I '{}' -P $CPUS bash -c "tesseract "{}" "{}" pdf"
	printf "[tesseract] Finished OCR\n"

	printf "Combining and stripping images\n"
	# Because textonly_pdf=1 only works on current versions (4.0+ of tesseract) and currently alignment/width seems incorrect (Tested with 5.0 alpha) remove all images from PDF so they don't get merged into final pdf
	gs -dNOPAUSE -sDEVICE=pdfwrite -dFILTERIMAGE -sOUTPUTFILE="${CROPPDF::-4}_noimage.pdf" -dBATCH $(find -wholename "${TMPPREFIX}_*.tiff.pdf" | sort -V)

	# Merge text-only pdf and image pdf into one file
	printf "[pdfmerge.py] Merging OCR'd text and Original PDF into final PDF\n"
	pdfmerge.py "$CROPPDF" "${CROPPDF::-4}_noimage.pdf" "$OUTPDF"
	printf "[pdfmerge.py] Done Merging.\n"
	printf "[cleanup] Removing temp files\n"

	# Enable Globing for cleanup
	set +f
	rm "${TMPPREFIX:2}"*

	if [ "$AUTOCROP" = "false" ]; then
		rm "${ORIGPDF::-4}_noimage.pdf"
	fi

	printf "Final output PDF @ $OUTPDF\n"
}

main
