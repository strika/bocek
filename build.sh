#!/usr/bin/env bash
# Convert checklist Markdown files to PDF via pandoc + XeLaTeX.
#
# Usage: ./build.sh [-p FORMATS] [-o DIR] [FILE.md ...]
#   -p FORMATS  comma-separated paper formats (default: a4)
#               supported: a4, a5, b5, letter
#   -o DIR      output directory (default: pdf)
#   FILE.md     files to convert (default: every *.md in the repo root
#               except README.md and CLAUDE.md)
#
# Output: DIR/<format>/<name>.pdf

set -euo pipefail

cd "$(dirname "$0")"

formats="a4"
outdir="pdf"

usage() { sed -n '2,12s/^# \{0,1\}//p' "$0"; exit "${1:-0}"; }

while getopts "p:o:h" opt; do
  case $opt in
    p) formats=$OPTARG ;;
    o) outdir=$OPTARG ;;
    h) usage ;;
    *) usage 1 ;;
  esac
done
shift $((OPTIND - 1))

if [ $# -eq 0 ]; then
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

IFS=',' read -ra format_list <<< "$formats"

for format in "${format_list[@]}"; do
  paper=$(paper_for "$format")
  mkdir -p "$outdir/$format"
  for src in "$@"; do
    out="$outdir/$format/$(basename "${src%.md}").pdf"
    # PDFs are committed, so builds must be reproducible: unchanged
    # checklists must rebuild byte-identical. Pin embedded timestamps to a
    # fixed date and derive the trailer ID (which would otherwise hash
    # pandoc's random temp path) from the content.
    id=$(cat "$src" <(echo "$format") | md5sum | cut -d' ' -f1)
    # Force tight spacing on every list: pandoc's gfm reader treats a list
    # followed by a trailing blank line at EOF as loose (extra item spacing).
    SOURCE_DATE_EPOCH=0 FORCE_SOURCE_DATE=1 pandoc "$src" \
      -V header-includes="\\special{pdf:trailerid [<$id><$id>]}" \
      -V header-includes="\\usepackage{enumitem}\\setlist[itemize]{itemsep=0pt,parsep=0pt}" \
      --from gfm \
      --pdf-engine xelatex \
      -V geometry:"$paper" \
      -V geometry:margin=15mm \
      -V mainfont="DejaVu Sans" \
      -V fontsize=10pt \
      -V lang=sr-Latn \
      -V pagestyle=empty \
      -o "$out"
    echo "$out"
  done
done
