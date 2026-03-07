# Issue Template and Labeler Sync Guide

This document keeps issue/PR labels consistent across:

- `.github/ISSUE_TEMPLATE/*.yml`
- `.github/labeler.yml`
- Repository label definitions in GitHub UI

## Current Issue Template Labels

Defined in templates:

- `bug` (`bug_report.yml`)
- `enhancement` (`feature_request.yml`)
- `question` (`question.yml`)

## Current PR Auto-Labels

Defined in `.github/labeler.yml`:

- `ci`
- `docs`
- `python`
- `sql`
- `docker`
- `kubernetes`
- `tests`

## Sync Checklist

Run this checklist when adding/changing templates or labeler rules:

1. If a new template label is introduced, create the same label in GitHub repository labels.
2. If a new `labeler.yml` rule is introduced, create that label in GitHub repository labels.
3. Keep label naming style consistent (lowercase, kebab/snake style, no duplicates by casing).
4. Verify with:
   - Opening a test issue from each template.
   - Opening a test PR touching files that should trigger each label rule.

## Recommended Label Baseline

Issue labels:

- `bug`
- `enhancement`
- `question`

PR/path labels:

- `ci`
- `docs`
- `python`
- `sql`
- `docker`
- `kubernetes`
- `tests`

Optional cross-cutting labels:

- `dependencies`
- `security`
- `performance`
