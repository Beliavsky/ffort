# Independent 0.50 composition checks

30 small synthetic sources combine the 0.50 internal WRITE array-element, numeric rank-three vector gather, MASKL/MASKR/SHIFTR, and CASE-header semicolon corrections with existing CHARACTER records, derived defaults, allocatable results, positioning and nonadvancing output. No future rank-one CHARACTER gather feature is included. No original utility or M_intrinsics source is replaced or claimed covered by this synthetic suite.

## Verified profiles

- 21 strict GNU Fortran / candidate executions with byte-for-byte independently specified output. Records, trailing blanks, leading blanks, case, signed zeros and final newlines are significant. No numeric token normalization or tolerance is used.
- Eight runtime safety cases and one static scatter-subset rejection. GNU compiles these only, without evaluating undefined values, invalid controls/bounds, or an unavailable second internal record. Both candidate stages require exact status, stdout, source path, line, column and named diagnostic; successful `--check` must be silent.
- 34 adversarial harness checks, including source/generator identity, file-only packaging, crash detection, exact record comparison, compiler-only profiles, diagnostic location, unexpected file output and candidate hash/version stability.

The initial immutable candidate was `/tmp/fortfront-050-case-preview-cli`, SHA-256 `3872c1ea71d75ca9076f35ae7c446d0bc65a9008dbb92b1c48f83a6ac509daa2`, version 0.50.0. Its source snapshot was `case-preview-minimal-source.zip`, SHA-256 `019587ddd729dc00dda2f9e5b43b9254f6c3901f1a6b88a951023aef175541e9`. Release certification must rerun against the final clean executable; this focused result is not aggregate certification.

## Initial evidence and one transparent correction

All 28 initially attempted source files remain byte-identical in `cases/` and `oracle-evidence/initial-attempts/`, pinned by the initial identity file. The first GNU profile recorded 20 executions and eight compile-only cases without a compiler/output mismatch. One executed source, `record_defaults_staged_items`, copied a whole derived object whose `a` and `b` components were undefined. GNU happened to copy it and print only the defined components; that observation is retained, not treated as a reliable defined-data oracle.

The first candidate retained its conservative undefined-record-copy boundary and stopped at that whole-record assignment with `read of uninitialized derived components`. The preserved source is now classified as a runtime safety case, with GNU compilation only. Its category, expected stdout and GNU mode changed, never its source bytes. A separately named `defined_record_copy_staged_items` explicitly defines both fields before the copy and passes both processors. No implementation correction or weaker comparison was used. A further independent REAL4/8 gather → INTEGER conversion → bit operation → element-file case covers both numeric families. Every other initial category, expected stdout, GNU mode and source is unchanged. Initial generator/manifest and all first observations are preserved alongside the source identities.

## Coverage and retained scope

- Each rank-three axis, duplicate indices, nondefault source bounds, logical shifts and 32/64-bit masks, exact B/O/Z records, and scalar loops covering all selected elements. No positive relies on rank-three RESHAPE, SUM or ANY.
- Self-reallocation and parenthesized INTENT(IN) gather snapshots; fixed, deferred and assumed CHARACTER file-element lengths; rank-one/two/three file elements and zero-length files.
- Undefined neighbors are not read; empty gathers skip base/scalar data but metadata-only KIND validates descriptors. Component values are staged into ordinary scalar operands where intrinsic component support is outside the existing contract.
- CASE same-line CALL and WRITE; fresh function array results, defined record copies, output implied-DOs and constant KIND conversions.
- Scalar-record slash restrictions are retained for array-element files. Colon can skip an unreached slash; a dynamically reached slash rejects. T-position overwrite is byte-exact and internal output does not disturb pending stdout.
- Runtime error fixtures prove unchanged observable prior/pending stdout and no newly created native file. A terminating CLI cannot expose the target after an error; these sources do not independently claim to inspect post-failure target memory. Owned native tests and code review cover single-element commit mechanics.

## Reproduction

```sh
python tests/release050_integration/test_runner.py
python tests/release050_integration/run_tests.py \
  --candidate /absolute/path/to/fortfront-interpreter \
  --gfortran /absolute/path/to/gfortran \
  --expected-sha256 EXPECTED_EXECUTABLE_SHA256
```

Omit `--candidate` for the GNU-only profile. GNU uses `-std=f2018 -pedantic-errors -fcheck=all -ffpe-trap=invalid,zero,overflow -O0`, disconnected stdin, fresh per-case working directories and a 30-second timeout. Its one temporary executable is discarded before the next case. No external input files or non-stdout native output units are used by these fixtures. Empty `inputs/` is deliberately absent; file-only ZIPs reproduce exactly. The runner rejects all unexpected candidate working-directory files.

`generate_cases.py` reproduces every source, manifest and identity file. The additive verifier hook runs the harness and source runner separately. Generated result JSON and logs are evidence, not source inputs.
