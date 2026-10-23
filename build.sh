#!/usr/bin/env bash
# Convert checklist Markdown files to PDF via pandoc + XeLaTeX.
#
# Usage: ./build.sh [-p FORMATS] [-o DIR] [FILE.md ...]
#   -p FORMATS  comma-separated paper formats (default: a4,b5,a5,a5-2up)
#               supported: a4, a5, b5, letter, a5-2up (two A5 pages
#               side by side on A4 landscape, to print and cut in half)
#   -o DIR      output directory (default: pdf)
#   FILE.md     files to convert (default: every *.md in the repo root
#               except README.md and CLAUDE.md)
#
# Output: DIR/<format>/<name>.pdf
#
# With no files given, standalone LaTeX sheets (every *.tex in the repo root
# except style.tex) are also built, on A4 only, to DIR/a4/<name>.pdf.

set -euo pipefail

cd "$(dirname "$0")"

formats="a4,b5,a5,a5-2up"
outdir="pdf"

usage() { sed -n '2,16s/^# \{0,1\}//p' "$0"; exit "${1:-0}"; }

while getopts "p:o:h" opt; do
  case $opt in
    p) formats=$OPTARG ;;
    o) outdir=$OPTARG ;;
    h) usage ;;
    *) usage 1 ;;
  esac
done
shift $((OPTIND - 1))

sheets=()
if [ $# -eq 0 ]; then
  for f in *.tex; do
    [ "$f" = style.tex ] || sheets+=("$f")
  done
  files=()
  for f in *.md; do
    case $f in README.md | CLAUDE.md) continue ;; esac
    files+=("$f")
  done
  set -- "${files[@]}"
fi

paper_for() {
  case $1 in
    a4) echo a4paper ;;
    a5) echo a5paper ;;
    b5) echo b5paper ;; # ISO B5, 176 x 250 mm
    letter) echo letterpaper ;;
    *) echo "Unsupported paper format: $1" >&2; exit 1 ;;
  esac
}

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

# PDFs are committed, so builds must be reproducible: unchanged checklists
# must rebuild byte-identical. Pin embedded timestamps to a fixed date and
# set the trailer ID (which would otherwise hash the random temp path and
# current time) from the content.
export SOURCE_DATE_EPOCH=0 FORCE_SOURCE_DATE=1
trailer_id() {
  local id
  id=$(cat "$1" <(echo "$2") | md5sum | cut -d' ' -f1)
  echo "\\special{pdf:trailerid [<$id><$id>]}"
}

# render SRC FORMAT OUT
render() {
  # Typography and layout live in style.tex.
  pandoc "$1" \
    -V header-includes="$(trailer_id "$1" "$2")" \
    --include-in-header style.tex \
    --from gfm \
    --pdf-engine xelatex \
    -V geometry:"$(paper_for "$2")" \
    -V geometry:margin=15mm \
    -V geometry:footskip=8mm \
    -V mainfont=Lato \
    -V fontsize=10pt \
    -V lang=sr-Latn \
    -o "$3"
}

# render_2up SRC OUT: A5 pages imposed two per A4 landscape sheet.
render_2up() {
  render "$1" a5 "$tmp/a5.pdf"
  cat > "$tmp/2up.tex" <<TEX
\\documentclass{article}
\\usepackage[a4paper,landscape]{geometry}
\\usepackage{pdfpages}
$(trailer_id "$1" a5-2up)
\\begin{document}
\\includepdf[pages=-,nup=2x1]{a5.pdf}
\\end{document}
TEX
  (cd "$tmp" && xelatex -interaction=batchmode 2up.tex > /dev/null)
  mv "$tmp/2up.pdf" "$2"
}

IFS=',' read -ra format_list <<< "$formats"

for format in "${format_list[@]}"; do
  [ "$format" = a5-2up ] || paper_for "$format" > /dev/null
  mkdir -p "$outdir/$format"
  for src in "$@"; do
    out="$outdir/$format/$(basename "${src%.md}").pdf"
    if [ "$format" = a5-2up ]; then
      render_2up "$src" "$out"
    else
      render "$src" "$format" "$out"
    fi
    echo "$out"
  done
done

# Standalone sheets set their own paper and styling.
for src in "${sheets[@]}"; do
  out="$outdir/a4/$(basename "${src%.tex}").pdf"
  mkdir -p "$outdir/a4"
  id=$(trailer_id "$src" a4)
  cp "$src" "$tmp/sheet.tex"
  (cd "$tmp" && xelatex -interaction=batchmode \
    "\\AddToHook{begindocument}{$id}\\input{sheet.tex}" > /dev/null)
  mv "$tmp/sheet.pdf" "$out"
  echo "$out"
done
