#!/usr/bin/sh

# This is script for the local generation of the PDF file
# You shall install pandoc and texlive packages to make it work

SOURCE_FILE_NAME="fp16_experiment_summary"
DEST_FILE_NAME="output.pdf"
INDEX_FILE="INDEX"
DATE=$(date "+%d %B %Y")

#pandoc -V geometry:margin=1in \
#       -f gfm+tex_math_dollars \
#       -s --toc -N \
#       -o ${DEST_FILE_NAME} \
#       -M date="$DATE" $(cat "$INDEX_FILE") >&1

#exit 0
#DEST_FILE_NAME_PROTECTED="pandoc-2-pdf-how-to_(protected).pdf"
#TEMPLATE="eisvogel_mod.latex"
DATA_DIR="pandoc"
PDF_ENGINE="pdflatex"

SOURCE_FORMAT="markdown_github\
+tex_math_dollars\
+backtick_code_blocks\
+pipe_tables\
+auto_identifiers\
+yaml_metadata_block\
+implicit_figures\
+table_captions\
+footnotes\
+smart\
+escaped_line_breaks\
+header_attributes"

pandoc -s -o "$DEST_FILE_NAME" -f "$SOURCE_FORMAT" --data-dir="$DATA_DIR" --toc --columns=50 --number-section --dpi=300 --pdf-engine "${PDF_ENGINE}" -M date="$DATE" $(cat "$INDEX_FILE") >&1
