# Contributing to simulatr

Thanks for considering a contribution. `simulatr` is under active redesign;
see `docs/projects/simulatr-improvement-plan.md` upstream for the broader plan.
This document covers the practical mechanics.

## Install for development

`simulatr` is an R package. From a fresh clone:

```r
install.packages("devtools")
devtools::install_deps(dependencies = TRUE)
devtools::load_all()
```

You will also need the suggested dev tooling:

```r
install.packages(c("testthat", "covr"))
```

## Run the test suite

```r
devtools::test()
```

The tests live under `tests/testthat/` and use the `testthat` 3rd edition.
Each exported function in `NAMESPACE` should have at least a smoke test.

To run a single test file:

```r
testthat::test_file("tests/testthat/test-check-functs.R")
```

## Check the package

Before opening a PR, run:

```r
devtools::check()
```

`R CMD check` should pass with 0 errors and 0 new warnings. CI runs
`R CMD check` on Ubuntu R-release; broader platform / R-devel matrices
will land in a later phase.

Line coverage is reported by `covr` and uploaded to Codecov:

```r
covr::package_coverage()
```

## What kinds of changes to PR

- Bug fixes with a regression test.
- Documentation improvements (README, vignettes, roxygen).
- New `simulatr_function` / metric examples.
- Test coverage improvements for already-exported functions.

Larger architectural changes (new S4 classes, schema changes, pipeline
contract, renames of exported functions) should be discussed in an issue
first — they are coordinated under the multi-phase redesign plan.

## Commit conventions

This repo uses Conventional Commits: `fix:`, `feat:`, `tests:`, `docs:`,
`ci:`, `chore:`. Branch from `main`; one feature per branch; squash on
merge is fine.

## License

By contributing, you agree your changes are released under the MIT
license (see `LICENSE.md`).
