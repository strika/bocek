# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Checklists for members of a polling station committee (*birački odbor*) in Serbia. Each checklist is a standalone Markdown file at the repo root (e.g. `glasanje.md`, the checklist for election day).

## Building PDFs

`build.sh` converts checklists to PDF with pandoc + XeLaTeX (font: DejaVu Sans).

```sh
./build.sh                    # every checklist, A4
./build.sh -p a4,b5           # several paper formats (a4, a5, b5, letter)
./build.sh -p b5 glasanje.md  # a single file
```

Output goes to `pdf/<format>/<name>.pdf`. The PDFs are committed: rebuild them in the same commit as any checklist change. Builds are reproducible (fixed timestamps and trailer ID), so unchanged checklists produce no git diff; keep it that way when changing the build. With no files given, every `*.md` in the root except `README.md` and `CLAUDE.md` is converted, so new checklists are picked up automatically. To add a paper format, extend `paper_for` in `build.sh` with a LaTeX `geometry` paper name.

## Content conventions

- Write in Serbian, Latin script, with full diacritics (č, ć, š, ž, đ).
- Each file starts with a single `# Ček lista za …` heading.
- Sections are `##` headings named by time of day (`## 6:00 - Priprema`, `## 20:00 - Zatvaranje`), in chronological order. Sub-phases inside a time block use `###`.
- Every item is a GitHub task-list entry (`- [ ] …`): one short action or condition to verify, ending with a period.
- Abbreviations used throughout: **BO** = birački odbor (polling station committee), **BM** = biračko mesto (polling station), **RS** = Republika Srbija.
