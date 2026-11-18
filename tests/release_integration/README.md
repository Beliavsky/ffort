# Release integration cases

These three independently specified GNU comparisons combine new features with
prior behavior: public generic dispatch with private CHARACTER specifics and
array constructors; REAL64/INTEGER elemental generic calls with array arithmetic;
and named derived-type generic dispatch with CLASS bound CHARACTER results,
CHARACTER arrays, concatenation and captured DT output.

Run `python3 tests/release_integration/run_tests.py --candidate EXE --gfortran gfortran`.
The runner checks both admission silence and execution values, using isolated
GNU compilation directories. Exact example byte comparisons are also recorded
in `docs/verification/0.18.0/exact-programs.json`.

The 0.21 hyperbolic-array-result fixture preserves the original sech body with
new automatic-array result/local drivers. Its literal oracle is independently
calculated from sinh/cosh/tanh at -1/4, 0, 1/4 and 1/2; GNU is a second check.
It covers rank-one/rank-two results, elemental calls, reductions, DIM, and zero
extents. See hyperbolic-array-provenance.json for the original body hash.

## 0.23 combined checks

`mutable_selection_original.f90` combines byte-preserved original IMINLOC and
VECTOR bodies with mutable module arrays initialized by rank-two RESHAPE, the
DIMENSION attribute, constant location results, MASK, DIM, BACK, reversed and
empty sections, and persistent writes. The new declarations and driver are not
original utility code. The runner verifies both body hashes and inclusion.
Three additional cases check initializer shape/constancy rejection and a
nonevaluating location KIND inquiry over undefined module storage.
