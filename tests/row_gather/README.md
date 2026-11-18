# Numeric matrix row-gather contracts

See `../../docs/ROW-GATHER.md` for supported forms and explicit boundaries.

Run from the repository root:

    python3 tests/row_gather/test_runner.py
    python3 tests/row_gather/check_provenance.py
    python3 tests/row_gather/run_tests.py --candidate /absolute/path/to/fortfront-interpreter

The manifest hashes every fixture. `provenance.json` independently identifies
three exact CRLF original utility bodies in nine complete wrappers. Module,
generic-interface and driver scaffolding is synthetic; no dependency body is
replaced. Existing historical fixtures elsewhere are never rewritten.

The runner separates execution agreement, safe implementation rejections,
GNU compile rejections and interpreter-only runtime safety checks. It does not
execute undefined-data or excessive-allocation probes under GNU. The defined
`shape_undefined_boundary` GNU inquiry is executed independently and explicitly
records the candidate's retained eager-value inquiry limitation. A failed GNU
compilation must match an explicit `gnu_compile: reject` entry. It never counts
as an execution oracle.

The native `test/test_row_gather.f90` program exercises separate producer,
adapter and runtime paths, including descriptor mutations, continued inline-IF
physical locations, result rank, and forbidden direct/scatter actuals.

## 0.53 numeric rank-one migration

`reject_rank1_base.f90` is unchanged. Numeric rank-one parsing now succeeds, but the fixture reads undefined data and is pinned to runtime failure at4:5, not GNU execution. These measured updates supersede the earlier rank-one rejection boundary; all other suite policies remain unchanged.
