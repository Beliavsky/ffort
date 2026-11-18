# Bounded array-constructor implied-DOs

Both `[ ... ]` and `(/ ... /)` constructors support ordered scalar/rank-one
INTEGER/REAL kind4/8, default LOGICAL and descriptor-known CHARACTER values, mixed
ordinary values and sibling implied-DOs, multi-item bodies and nesting. Existing
typed CHARACTER padding/truncation remains supported. Explicit index type-specs,
nonempty typed numeric/logical constructors and rank-two/three leaves remain
outside the subset. Runtime CHARACTER length support is restricted to the
[descriptor-known contract](DYNAMIC-CHARACTER-CONSTRUCTORS.md), not arbitrary
value-dependent lengths.

The declared scalar INTEGER4/8 index contributes only its type/kind to a new
statement entity. Its value and definedness never replace the outer variable,
including active executable DO counters, module data, procedure hosts, saved
locals and INTENT(IN)/absent OPTIONAL dummies. Existing declaration/scope limits
remain: scalar INTEGER POINTER/ALLOCATABLE and mutable main-program host
association are not added. Callees and recursive frames have independent index
activation; functions reading outer module/host data still see that data.

The index scope includes the complete controlling implied-DO. Own-index value
reads in its controls and nested same-name indices reject; sibling reuse is
allowed. Supported KIND/DIGITS/RADIX/HUGE operand trees and fixed-length LEN
inquiries inspect metadata without reading the pending index. Bounds and step
are evaluated once per loop invocation; zero step and checked INTEGER narrowing
or increment overflow fail. Zero-trip loops do not evaluate body data, but their
complete metadata/source identities are still validated.

Constructors snapshot values in source order once per syntax activation. Each
iteration refreshes operand/function caches. Assignment and output retain their
existing temporary-before-commit behavior; this does not promise rollback of
arbitrary earlier side effects in user functions.

Limits are eight lexical implied-DO levels,64 body items per loop, the configured
max_array_elements (default1,000,000) for emitted values and aggregate iterations
per constructor expansion,16MiB staged CHARACTER data, and the unchanged shared
work budget. Existing total live-array and cached-result caps still apply.
New scratch/result allocations report checked failures. No cap was increased.

Strict frontends agree on complete lexical owner/source declaration identity,
ordered body/control AST edges, scalar index type/kind, shape/CHARACTER caches,
source positions and neutral public-IR fields. Owner links are identities, not
recursive tree edges. Source-free guards reject forged owners, cycles, stale
shapes and detached value use.

Tests preserve complete original `compare_vec_strings`, `compare_vec_strings_`
and `default_character` bodies and CRLF bytes. The wrapper executes against GNU
including empty sets, duplicates and optional forwarding. Main focused99 cases
and22 inquiry cases pass, with72 total GNU executions; negatives are compile
only/rejections, never undefined-behavior execution oracles. Native coverage is
744 runtime/IR,990 producer and49 adapter checks. Exact Decimal/signed-zero and
byte-preserving CHARACTER comparators are covered by47 adversarial checks.

The user-authorized full utility working copy changes only nmax10**8 to10**5.
It still fails compilation at800:17 (`read (iu,*) nx_` in `read_alloc_char`),
external list-directed numeric READ. Both check and100m-step run reject before
stdout. This is not successful full-library execution.
