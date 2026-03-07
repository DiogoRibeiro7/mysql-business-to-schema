# Branch Protection Checklist

Use this checklist when configuring branch protection rules in GitHub.

## Base Branch: `develop`

Enable:

- Require a pull request before merging
- Require approvals (recommended: at least 1)
- Dismiss stale approvals when new commits are pushed
- Require conversation resolution
- Require status checks to pass before merging
- Require branches to be up to date before merging

Required checks to add (exact visible names):

- `Pull Request Checks / PR Validation`
- `Pull Request Checks / Schema Validation`
- `Pull Request Checks / Code Coverage`
- `Pull Request Checks / Dependency Review`
- `Pull Request Checks / Performance Impact`
- `Pull Request Checks / Documentation Check`
- `Pull Request Checks / PR Summary`
- `Main CI/CD Pipeline / Code Quality Checks`
- `Main CI/CD Pipeline / Python Tests (3.10)`
- `Main CI/CD Pipeline / Python Tests (3.11)`
- `Main CI/CD Pipeline / JavaScript/TypeScript Tests`
- `Main CI/CD Pipeline / Integration Tests`
- `Main CI/CD Pipeline / Security Scanning`
- `Code Quality / Code Quality Checks`
- `Code Quality / SQL Quality Checks`
- `Database Examples Test Suite / test-schemas`
- `Database Examples Test Suite / validate-schemas`
- `Database Examples Test Suite / test-generators`
- `Database Examples Test Suite / performance-analysis`
- `Database Examples Test Suite / summary-report`
- `Normalization Exercises Check / normalization-check`

## Base Branch: `main`

Use all required checks from `develop`, plus PR workflows configured only for `main`:

- `Documentation Check / Documentation Check`
- `Schema Testing / Schema Testing`
- `Tools Testing / Test Python Tools`
- `Web Interface Tests / Test Web Interface`
- `SQL Validation / SQL Syntax Validation`
- `Security Scan / Security Scanning`

## Maintenance Rule

Whenever workflow triggers, job names, or matrix names change:

1. Update this checklist.
2. Update branch protection required checks in GitHub settings.
3. Validate with a test PR to each protected branch.
