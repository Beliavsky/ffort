# Bounded process-query verification

Run from the package root:

```sh
python3 tests/process_queries/generate_cases.py --check
python3 tests/process_queries/test_runner.py
python3 tests/process_queries/run_tests.py --candidate /path/to/fortfront-interpreter --gfortran gfortran
```

The frozen corpus has 100 focused cases. Its GNU baseline comprises 34 successful,
defined executions, 38 compile-only subset/safety boundaries, and 28 compilation
rejections. Compile-only cases are never executed by GNU, including undefined
outputs, input/output aliasing, missing allocation, negative argument numbers,
and storage forms outside the interpreter subset. GNU accepting a source at
compile time is not a claim that its execution is safe or standard-conforming.

`generate_cases.py` deterministically regenerates source bytes, manifest, hashes,
and provenance. `--check` compares the entire fixture inventory and rejects stale
or edited files. The runner verifies that replay before any candidate invocation.
`test_runner.py` adversarially checks exact CHARACTER spacing and record endings,
empty stdout/stderr, exit codes, diagnostic-path spoofing, Decimal numeric
precision and signed zero, nonfinite/overflow rejection, tiny nonzero values,
invalid bytes, timeout/crash handling, source mutation, logical
argv[0] forwarding, and candidate mutation during verification.

Captured stdout/stderr use reversible Latin-1 byte mapping, and CHARACTER record
comparison is byte-exact on the verified Linux platform. CRLF and LF do not
compare equal; blank padding, blank records and final terminators are preserved.
The unused numeric-token helper compares Decimal values exactly with no
tolerance, rejects NaN/Inf (including payload spellings) and values above binary64
maximum, preserves signed integer/real zero and arbitrarily tiny nonzero values,
and retains record boundaries and terminators.

## The original utility

`original_exe_name.f90` embeds exactly lines 549–557 of
`../utilities_slices/source/xutilities.f90`, including every CRLF, its commented
GETARG call, and the literal backslash used to join cwd and program name. Only an
explicit main/internal-procedure wrapper is added. The original full source's
SHA-256 is
`c257f1b2ee4911e979bb38cf6db044d8593c95e76ab1a7e7a7a769a298698883`.
`provenance.json` records the exact body hash and source line range.

Each execution uses its own temporary directory. The runner stages the frozen
fixture under the logical source filename `program.f90` (or the explicitly
specified alternate spelling). The candidate sees that filename as its source
argument. GNU is launched with `subprocess.run(args=[logical_source_filename],
executable=reference_binary)` in the same directory, so its argv[0] is identical.
The expected cwd and 1000-character result are independently constructed from
that controlled invocation, not learned from either executable. There are no
random absolute paths in the frozen fixture source or manifest expectations.

This makes the unchanged routine a real execution agreement. It does not claim
that the complete utility module or unsupported GETARG form now executes.

## Processor and subset boundaries

- GETCWD is a GNU extension. Its tests explicitly use `-std=gnu`. Command-only
  cases use `-std=f2018`. Both use `-pedantic-errors -fcheck=all -O0` in fresh
  directories, preventing stale module reuse.
- GNU 14.2's actual GETCWD first keyword is **COUNT**, despite the manual naming
  the argument C. In the [official GCC 14.2 source](https://raw.githubusercontent.com/gcc-mirror/gcc/releases/gcc-14.2.0/gcc/fortran/intrinsic.cc),
  line 3159 defines `c = "count"`, and lines 3329–3332 register it for GETCWD.
  The interpreter and positive test follow the actual COUNT/STATUS interface.
  C and CWD are explicit unknown-keyword rejection cases. Positional CHARACTER
  output is the clearest portable GNU-extension spelling.
- A too-short GETCWD output becomes blanks with a nonzero processor-specific
  status. A zero-length output also returns an error. Tests never pin errno.
- A nonempty truncated command VALUE contains the prefix, LENGTH reports the
  full argument length, and STATUS is -1. For a present zero-length VALUE, GNU
  14 returns a positive retrieval error instead; tests assert its sign, not the
  implementation's numeric value. Omit VALUE for a length-only query.
- The interpreted invocation has the CLI source filename as argument zero and
  no positive-numbered user arguments. Interpreter options are not exposed.
  Separate fixtures cover `./` spelling, spaces, absent arguments and INT32_MAX.
- Outputs are whole local scalar default CHARACTER or INTEGER(4), including
  already-allocated scalar CHARACTER and main-program SAVE storage with the
  existing required constant initializers. Dummy,
  optional, host/module, pointer and procedure-SAVE outputs are bounded-subset
  rejections. The existing host-association and CHARACTER POINTER declaration
  gates reject those fixtures before query validation; the manifest identifies
  these separately. INTEGER(8) control/output extensions are excluded.
- An input expression temporary may reuse an output symbol (`NUMBER=n+0`,
  `LENGTH=n`). Direct variable aliases and duplicate outputs are rejected.
- Ordinary impure functions and source procedure/generic/data shadows are
  tested. PURE and SIMPLE queries reject. A source generic with no matching
  specific does not fall back to the intrinsic in this bounded interpreter,
  even though GNU can extend an intrinsic generic.
- Exactly 65536-byte CHARACTER outputs succeed. Larger fixed outputs reject
  during checking; allocating a larger deferred output fails at runtime before
  the process query. Native API context and descriptor/resource atomicity are
  verified separately by the implementation's API tests.

Reference behavior: [GETCWD](https://gcc.gnu.org/onlinedocs/gfortran/GETCWD.html)
and [GET_COMMAND_ARGUMENT](https://gcc.gnu.org/onlinedocs/gfortran/GET_005fCOMMAND_005fARGUMENT.html).

The runner records the manifest/source hashes, runner/generator hashes, compiler
flags and version, each check/run result, and the candidate's initial and final
SHA-256. A changed candidate makes the run fail. Successful checking must have
exactly empty stdout/stderr, successful execution exactly empty stderr, and
negative executions must match the required phase and emit a diagnostic.

## Recorded feature verification

The 100-case candidate/GNU run in `results.json` passed against candidate SHA-256
`82db4cd9b2c2e96c15d3cadca198b1dcf99a175081ff758be10c64167c2d23d3`,
unchanged at the end of the run. All 28 harness self-tests and generator replay
also passed. This is focused process-query evidence, not the complete release
regression or native API test result.

Independent native programs pass 328 public-IR/adapter/runtime/API checks and
12 producer checks, including transitive PURE/SIMPLE guards, logical invocation
reset/inheritance, fallback argv0, malformed metadata and silent budget failure.
The feature binary incorporates the complete 0.44 baseline, including its
independent local internal-WRITE VOLATILE exclusion.
