---
title: "simulatr: Pipeline-First Simulation Studies in R"
tags:
  - R
  - simulation
  - reproducibility
  - Nextflow
authors:
  - name: Eugene Katsevich
    orcid: 0000-0001-9591-7843
    corresponding: true
    affiliation: 1
  - name: Timothy Barry
    orcid: 0000-0002-4356-627X
    affiliation: 2
affiliations:
  - name: Department of Statistics and Data Science, The Wharton School, University of Pennsylvania
    index: 1
  - name: Department of Biostatistics, Bloomberg School of Public Health, Johns Hopkins University
    index: 2
date: 16 May 2026
bibliography: paper.bib
---

# Summary

`simulatr` is an R package for designing reproducible simulation studies
that scale from a laptop to a high-performance computing cluster
without rewriting any of the simulation code. A study is built from
four typed components — a `simulatr_model` (the data-generating
distribution), `simulatr_method` (the procedure under evaluation),
`simulatr_metric` (the performance criterion), and the
`simulatr_study` they plug into — and realised with three verbs:
`simulatr_generate()`, `simulatr_run()`, `simulatr_evaluate()`. A
companion Nextflow [@nextflow] pipeline,
`simulatr-pipeline`, consumes a saved study and shards it across
Slurm/LSF/cloud, automatically benchmarking memory and runtime per
parameter row, retrying on out-of-memory, and writing one shard per
`(method, grid_row, chunk)` plus a `memory.parquet` collected from the
kernel's view of resident set size. The package and pipeline are
joined by an explicit on-disk contract (`inst/extdata/contract.json`)
asserted by the pipeline at workflow start, so they can be versioned
independently. `simulatr` is MIT-licensed and tested across
{Linux, macOS, Windows} × {R-release, R-devel}.

# Statement of need

Methodological statisticians have long supported simulation studies
in R. Bien's `simulator` [@simulator] introduced the typed
`Model`/`Method`/`Metric` vocabulary that `simulatr` adopts; Chalmers'
`SimDesign` [@SimDesign] structured the design–generate–analyse–
summarise cycle and integrated `future` for parallelism; Joshi and
Pustejovsky's `simhelpers` [@simhelpers] focused on Monte Carlo
standard errors and convergence diagnostics; Eronen's `parSim`
[@parSim] provided lightweight `parallel`-backed loops over a
condition grid. Each occupies a coherent niche centred on the R
session as the orchestrator of computation.

`simulatr` fills a gap that none of these address: the simulation
study whose total compute exceeds the budget, time, or memory of any
single R session, and which therefore needs to live on a workflow
runner. A typical statistical-genetics simulation in our group
involves 20–100 methods on 50–200 parameter rows at 500–2000
replicates, with per-replicate memory footprints from 100 MB to
20 GB. R-session orchestration breaks down here: a single `future`
plan cannot retry one row at higher memory while the others succeed,
cannot resume a run after a node failure, and produces a single
in-memory result object that itself can be tens of GB. The pragmatic
response in our group, and we believe in many applied-methodology
groups, has been ad-hoc shell scripts wrapping per-package R sessions
on Slurm.

`simulatr` makes the workflow runner — Nextflow [@nextflow], whose
nf-core community [@nfcore] has standardised reproducible bioinformatics
workflows — a first-class citizen. The R package's job is to specify
the study and validate it on the laptop; the pipeline's job is to
parallelise, retry, and persist. They communicate through a frozen
on-disk contract: shard layout, parquet schemas, error-channel JSON
sidecars, and an RNG protocol that is invariant under reordering of
the parameter grid. Memory accounting is opinionated: we collect both
R-heap allocations (`bench::mark`) and kernel-level peak resident set
size (Slurm `sacct` or a portable `ps` sampler) so a user can diagnose
whether a memory blowup lives in R or in compiled code under it. The
package additionally exposes `simulatr_session_info()` for embedding
session, contract version, and contract hash into every result
artifact.

`simulatr` is in active use in the Katsevich Lab and in the
collaborator-facing `sceptre` [@sceptre] simulation pipeline for
single-cell CRISPR screens. We hope it lowers the activation energy for
methodologists in similar settings whose simulations have outgrown a
single R session.

# Architecture

A `simulatr_study` carries a `parameter_grid` (rows are problem
settings, with an optional `ground_truth` list-column),
`fixed_parameters` (`B`, `seed`, study-wide constants),
and named lists of `simulatr_model`, `simulatr_method`, and
`simulatr_metric` components. Constructors validate every component's
formals against the grid at build time, so a typo in a method's
signature fails on the laptop, not after eight hours on the cluster.

```r
study <- simulatr_study(
  parameter_grid   = parameter_grid,
  fixed_parameters = list(B = 1000, seed = 4),
  models  = list(lm_model = lm_model),
  methods = list(ols = ols, lasso = lasso),
  metrics = list(rmse = rmse)
)
simulatr_check(study, B = 2)   # laptop sanity check
```

Replication uses `seed_b = seed + run_id`; reordering grid rows does
not perturb seeds. The Nextflow pipeline reads the same study object,
benchmarks per-`(method, grid_row)` resource use, fans out work as
Slurm array jobs, and emits parquet shards under the contract layout.

# Acknowledgments

We are grateful to Jacob Bien for the `simulator` package, whose
typed-component vocabulary inspired this redesign of `simulatr`. The
1.0 implementation builds on Tim Barry's earlier work on the
package's lifecycle and its initial Nextflow integration. We thank
the Katsevich Lab for testing the alpha and the nf-core community for
documentation that made the pipeline migration straightforward.

# References
