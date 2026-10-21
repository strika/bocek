# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Checklists for members of a polling station committee (*birački odbor*) in Serbia. Content only: there is no code, build, lint or test tooling. Each checklist is a standalone Markdown file at the repo root (e.g. `glasanje.md`, the checklist for election day).

## Content conventions

- Write in Serbian, Latin script, with full diacritics (č, ć, š, ž, đ).
- Each file starts with a single `# Ček lista za …` heading.
- Sections are `##` headings named by time of day (`## 6:00 - Priprema`, `## 20:00 - Zatvaranje`), in chronological order. Sub-phases inside a time block use `###`.
- Every item is a GitHub task-list entry (`- [ ] …`): one short action or condition to verify, ending with a period.
- Abbreviations used throughout: **BO** = birački odbor (polling station committee), **BM** = biračko mesto (polling station), **RS** = Republika Srbija.
