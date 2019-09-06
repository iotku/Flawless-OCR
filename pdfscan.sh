#!/bin/bash
set -euf -o pipefail
ORIGPDF="$1"
OUTPDF="$2"
# Requirements
#	- ghostscript
#	- tesseract-ocr
#	- pdfmerge.py (by Georg Sauthoff :: https://raw.githubusercontent.com/gsauthof/utility/master/pdfmerge.py )
# 	- pdfcrop (from texlive-extra-utils)
#	- pdfinfo
#	- xargs

# Bugs: Doesn't maintain bookmarks

TMPPREFIX=$(mktemp --suffix=pdfscan -p .) # Dry run should produce name without creating redundant file, but man page calls it unsafe for whatever reason...
# Crop to A4 with 20 (pixels?) margins
# Requires: texlive-extra-utils
echo "[pdfcrop] start"
pdfcrop --verbose --papersize a4 --margins "20 20 20 20" "$ORIGPDF" "${TMPPREFIX}.pdf" 
echo "[pdfcrop] done."

CROPPDF="${TMPPREFIX}.pdf"

CPUS=$(getconf _NPROCESSORS_ONLN)

# If expr returns negative value it will return 1 which will kill script
PAGES=$(pdfinfo $CROPPDF | grep Pages | awk '{print $2}')
if [ "$PAGES" -lt "$CPUS" ]; then
	SPLITBY=1
else
	SPLITBY=$(expr "$PAGES" / "$CPUS")
fi

SPLITCOUNT=0
export OMP_THREAD_LIMIT=1 # Be sure to Only use one thread per tesseract instance
# Can Probably parallelize splitting as well.
for (( i = 1; i <= "$PAGES"; i += $(expr "$SPLITBY" + 1) ))
do
SPLITCOUNT=$((SPLITCOUNT+=1))
# Convert to tiff (for input to tesseract ocr), because we're merging into the original PDF quality/color doesn't matter much as long as the resolution is appropriate for OCR
echo "[gs] Converting to tiff to prepare for scan."
if [ $(expr "$i" + "$SPLITBY") -gt $PAGES ]; then
	ENDPAGE=$PAGES
else
	ENDPAGE=$(expr "$i" + "$SPLITBY")
fi

# Consider using a different DEVICE if it may improve OCR (Testing required)
gs -o "${TMPPREFIX}_${SPLITCOUNT}.tiff" -dFirstPage=${i} -dLastPage=${ENDPAGE} -sDEVICE=tiffgray -sCompression=lzw -r300 "$CROPPDF" # Find faster method? -r300 is 300 DPI which should be suitable for OCR
echo "[gs] done."
done

# Tesseract pdf generation is NOT lossless and produces artifacts compared to the original PDF
# argument -c textonly_pdf=1 would produce image-less pdf (making gs -dFILTERIMAGE irrelevant), but alignment/width seems off
# Thus we will strip images later before merging into a pdf
echo "[tesseract] Starting OCR"
find . -wholename "${TMPPREFIX}*.tiff" | sed 's/.*/"&"/' | xargs -I '{}' -P $CPUS bash -c "tesseract "{}" "{}" pdf"
echo "[tesseract] Finished OCR"

TIFFLIST=""
for (( i = 1; i <= $SPLITCOUNT; i += 1))
do
	TIFFLIST="$TIFFLIST ${TMPPREFIX}_${i}.tiff.pdf"
done

echo "Combining and stripping images"
OCRFILE="${TMPPREFIX}_noocr.pdf"
# Because textonly_pdf=1 only works on current versions (4.0+ of tesseract) and currently alignment/width seems incorrect (Tested with 5.0 alpha) remove all images from PDF so they don't get merged into final pdf
gs -dNOPAUSE -sDEVICE=pdfwrite -dFILTERIMAGE -sOUTPUTFILE="${CROPPDF::-4}_noimage.pdf" -dBATCH $TIFFLIST

# Merge text-only pdf and image pdf into one file
echo "[pdfmerge.py] Merging OCR'd text and Original PDF into final PDF"
pdfmerge.py "$CROPPDF" "${CROPPDF::-4}_noimage.pdf" "$OUTPDF"
echo "[pdfmerge.py] Done Merging."
echo "[cleanup] Removing temp files"

# Enable Globing for cleanup
set +f 
rm "${TMPPREFIX:2}"*

echo "Final output PDF @ $OUTPDF"
