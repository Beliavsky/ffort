# Multi-object allocation tests

Run `python tests/multi_allocation/run_tests.py --candidate /absolute/path/to/interpreter --gfortran gfortran`.
Run `python tests/multi_allocation/test_runner.py` for harness checks.

Tests cover numeric/logical/CHARACTER kinds and ranks, non-unit bounds, empty
objects, 64/65-object limits, first/middle/last STAT failures, successful prefixes,
untouched suffixes, descriptor retention, contextual names, DO loops, module and
dummy storage, conservative dependencies, side-effect boundaries and total caps.

`typed_character_failure_descriptor` has a specification-based expected result
and GNU compile-only evidence because GNU 14.2.0 modifies the failed descriptor.
`stat_dependency` is rejected under the standard even though GNU accepts it.
Resource-policy failures and valid unsupported forms are labeled separately.
See ../../docs/MULTI-OBJECT-ALLOCATION.md for the complete bounded contract.
