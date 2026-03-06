# Testfiles.jl

[![Build Status](https://github.com/hexaeder/Testfiles.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/hexaeder/Testfiles.jl/actions/workflows/CI.yml?query=branch%3Amain)

A single macro, `@testfile`, for running Julia test files with clean, noise-free output.

## Motivation

When a test suite grows across many files, running them all with `include` produces an
avalanche of output from passing tests that makes failures hard to spot. `@testfile` solves
this by capturing each file's output and printing only a one-line summary — unless something
fails, in which case the full output is revealed.

## Behaviour

- Each file is always included inside a **fresh anonymous module**, so there are no
  name-collision issues between files and no global namespace pollution.
- When called **outside** a `@testset`, the file runs normally with all output visible
  (useful for running a single file interactively).
- When called **inside** a `@testset`, output is captured and suppressed on success.
  Failures or errors in any nested `@testset` within the file are detected recursively.

## See also

[SafeTestsets.jl](https://github.com/YingboMa/SafeTestsets.jl) takes a similar approach of
isolating each `@testset` in its own module. The key difference is that `@testfile` operates
at the file level and additionally suppresses output of passing files.
