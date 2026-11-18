# Independent keyword-argument verification

This suite verifies keyword actual arguments for the interpreter's supported
array intrinsics, inquiries, functions and subroutines. It does not import the
interpreter implementation. GNU Fortran is a separate source-validity/output
oracle, never an execution backend for the interpreter.

## Reproduce

After building the interpreter, run:

```sh
python3 tests/keyword_arguments_independent/test_runner.py
python3 tests/keyword_arguments_independent/run_tests.py --candidate /path/to/fortfront-interpreter --gfortran gfortran
```

`generate_cases.py` recreates the checked-in corpus and its manifest byte for
byte. The harness accepts a single executable path, including paths containing
spaces; it never invokes a shell. Each GNU compilation uses a fresh temporary
directory so module files from other cases cannot satisfy imports. Flags are
`-std=f2018 -pedantic-errors -fcheck=all -O0`. Each individual tool run has a
15-second timeout.

## Cases and expectations

The manifest contains 446 cases:

- 311 successes must match independently specified expected output, in both GNU
  execution and the interpreter. Numeric reduction/product expectations use
  Python arithmetic over explicit coordinates. INTEGER outputs are compared
  exactly; REAL64 cases use tight tolerances where needed.
- 105 invalid cases must be rejected by both GNU and the interpreter. Static
  failures must produce no program output, including cases with PRINT before
  the bad call or bad calls in unreachable branches.
- 8 standard-valid but unsupported cases must compile with GNU but fail in the
  interpreter before output. They retain boundaries for intrinsic KIND,
  unsupported elemental keywords, array-valued bound inquiries, and more than
  16 procedure arguments.
- 22 runtime safety cases must pass interpreter `--check`, then fail execution
  with exit status 2 and the intended diagnostic. Their prior output must be
  preserved exactly. GNU checks compilation only: undefined reads, conservative
  alias rejection and interpreter resource limits are not GNU runtime oracles.

Coverage includes all six ARRAY/DIM/MASK keyword permutations for each reduction,
INTEGER/REAL32/REAL64 arrays, both rank-two dimensions, positional-prefix calls,
omitted DIM with named MASK, scalar false masks, empty axes, reversed sections,
nested products and reductions, and inquiry shape access without reading
uninitialized elements. Standard keyword names for DOT_PRODUCT and MATMUL are
checked with reversed source order and mixed case.

Procedure cases cover module imports, intrinsic-name shadowing, declaration
order differing from dummy order, nested calls, scalar/rank-one/rank-two type-converting intrinsic
actuals, mixed types, 16 reordered arguments, 63-character names, continuation
around `=`, OUT/INOUT binding, frozen element subscripts, expression snapshots,
disjoint writable sections, read-only aliases and nested OUT definedness loss.

Malformed/unsafe calls include unknown, duplicated and case-duplicated names,
positional/keyword collisions, positional arguments after a keyword, missing
required arguments, wrong type/kind/rank, non-definable outputs, input-dummy or
DO-variable writes, invalid DIM, nonconforming MASK, uninitialized reads,
overlapping writable arguments, bad bounds/strides, and argument/step limits.
The positional `(ARRAY,MASK)` reduction overload cannot be followed by `DIM=`;
GNU rejects that collision. `(ARRAY,MASK=...,DIM=...)` is valid.

## Harness integrity

`test_runner.py` has 14 tests for generator reproducibility (including the exact
set of case files), finite/tolerant numeric comparisons, exact token counts,
status codes, required diagnostics, stdout leakage and source-path diagnostic
spoofing. `results.json` records the actual tools and versions, source/manifest
hashes, candidate executable hash, complete stage results and expectations.
Read the recorded result, not this coverage description, to assess a package.
Passing these selected tests does not establish full Fortran conformance,
production-sandbox security, or Windows execution.
