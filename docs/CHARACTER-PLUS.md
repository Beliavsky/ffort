# Defined CHARACTER `+`

Binary `+` may select a visible module `interface operator(+)` specific when
at least one operand is CHARACTER. This extends an intrinsic operator to a
signature for which no intrinsic operation exists; it does not redefine
numeric addition. For example, a CHARACTER/INTEGER specific can return a string,
an INTEGER, a LOGICAL, or another already-supported scalar function result.
The specific's declaration determines the result, not the operands.

## Bounded contract

- Exactly two required INTENT(IN) operands. Exact type, INTEGER/REAL kind and
  rank resolution; no coercion, swapped-operand invention or result-type-only
  resolution. Existing duplicate/ambiguous signature checks remain in force.
- Existing module visibility and USE ONLY rules, private specifics exported by
  a public operator, and host-visible module-private operators remain supported.
- Scalar specifics and existing supported explicit/assumed-shape array dummies.
  ELEMENTAL scalar specifics lift to conforming arrays, including rank three,
  scalar expansion, empty results and reversed sections. Existing shape,
  allocation, CHARACTER-length, recursion and execution limits remain unchanged.
- `+` keeps intrinsic additive precedence and left associativity. It does not
  acquire the lower precedence of a custom dotted operator such as `.plus.`.
- Numeric `+`, existing derived-type operators, and custom dotted operators retain
  their previous behavior. Unary CHARACTER `+`, other intrinsic-symbol operators
  without a derived operand, VALUE/OPTIONAL operator dummies, type-bound generic
  operators, and new function forms are not added by this change.

The subset recognizer records an ordinary function call. The independent adapter
checks the source operator, visible interface and selected specific, operand
identity/type/kind/rank, declared result and canonical result metadata. The
runtime uses the existing checked function evaluator and elemental snapshots;
it does not re-resolve source interface names from public IR.

## Retained producer correction 0077

STANDARD-mode semantic inference no longer rewrites CHARACTER `+` into `//`.
Lazy-mode convenience concatenation retains its previous default behavior.
The canonical metadata query resolves the visible defined `+` specific and its
declared result rather than guessing the operand type.

The exact utility dependency also needs a bounded named-generic correction:
`str(i)` selects `str_int(i,ndigits,prefix)` with two omitted OPTIONAL dummies.
Named-generic metadata now maps present positional/keyword actuals to source
formal names and permits omission only of source-declared OPTIONAL formals.
Missing required, excess, duplicate, unknown-keyword, wrong-type/kind/rank and
ambiguous candidates remain rejected. Omitted formals contribute no elemental
rank. Operator matching explicitly disables this optional-omission path and
still rejects OPTIONAL operands. No registry entry is added.

## Original-source evidence

`tests/character_plus/original_closure.f90` contains the exact original CRLF bytes
of `char_plus_char` (xutilities lines 962–967), `char_plus_int` (969–976), and
`str_int` (2096–2118). It retains their declarations, lengths, statements and
comments. `char_plus_int` still calls `str(i)`, resolved to the actual original
`str_int`; there is no replacement helper or body rewrite.

The module, operator interfaces, driver and restricted `str` generic are new
scaffolding. Only the required original `str_int` specific is bound in that
restricted generic; the complete original utility module/dependency graph is
not claimed to work. `provenance.json` records the source, body and closure hashes.
The full source still rejects at line 9329:55 with the unchanged total-array
resource limit, independently of these exact routine tests.

The closure's output, including significant CHARACTER padding, is byte-equal
between the interpreter and strict GNU Fortran. The original ABS of the most
negative default INTEGER remains a checked runtime-overflow boundary. It is not
rewritten and no undefined GNU runtime result is used as its oracle.

## Checks and a separately recorded GNU discrepancy

The focused suite has 52 source cases. All successful output comparisons are
exact bytes, including spaces, trailing blanks, case, signs and record endings.
Successful `--check` must be silent. The two native programs have 59 combined
producer/helper/adapter/runtime assertions, including invalid public-IR indices,
OPTIONAL omission mapping and preserving the lazy helper's default behavior.
Five harness tests protect strict comparisons and the scoped oracle exception.

One new alias test independently expects `c_1 |`, `b_2 |`, `a_3 |` for an
assignment from a reversed CHARACTER array plus an INTEGER vector. GNU Fortran
14.2.0 at O0 produces the first record correctly but blanks the CHARACTER input
of subsequent elements when a longer ELEMENTAL result is truncated into the
shorter overlapping destination. GNU O2 and O3 agree with the independent
expectation and interpreter. The maintained runner records O0 separately,
requires O2 and the explicit correct bytes, and permits only the exact known O0
observation or the correct result. It never permits that discrepancy in candidate
output. This is not reported as an O0 differential pass. Other source cases use
GNU's default optimization; invalid/runtime-boundary cases are compile-only
references, not executed GNU undefined behavior.

Reproduce:

```
python3 tests/character_plus/run_tests.py --candidate /path/to/interpreter --gfortran gfortran
python3 tests/character_plus/test_runner.py
python3 tests/character_plus/check_provenance.py /path/to/original/xutilities.f90
fpm test --profile debug --flag '-ffree-line-length-none'
```

The isolated worker used an app/library debug build and manually linked the two
new native programs plus 18 relevant existing native programs, avoiding an
uncoordinated full native rebuild. Combined release verification is separate.
The GNU reference uses `-std=f2018 -pedantic-errors -fcheck=all
-ffpe-trap=invalid,zero,overflow`; these reference flags are not a claim that the
entire interpreter was built with `-fcheck=all`.

Language context: Intel's [defined operations documentation](https://www.intel.com/content/www/us/en/docs/fortran-compiler/developer-guide-reference/2025-1/defined-operations.html)
distinguishes extending intrinsic operators from redefining intrinsic operations
and includes CHARACTER `+` as an extension example. The interpreter's contract
above is intentionally narrower than all standard-defined operations.
