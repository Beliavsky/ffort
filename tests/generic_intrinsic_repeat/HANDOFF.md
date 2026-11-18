# REPEAT validation handoff

Run from the integrated repository root. Put the intended GNU compiler and
`fpm` on PATH. Actual executions are evidenced separately in the retained first/hardened
result files and central native log. Keep the immutable CLI outside the writable build
cache and retain its SHA-256 in the runner's JSON.

## Read-only source preservation and runner checks

```sh
python3 tests/generic_intrinsic_repeat/check_original.py
python3 tests/generic_intrinsic_repeat/test_runner.py
```

The default original is `tests/utilities_slices/source/xutilities.f90`.
Use `--original /path/to/xutilities.f90` only for the same raw SHA-256 recorded
in the manifest. No source/body adaptation is performed by this audit.

## Focused source checks and actual execution

```sh
python3 tests/generic_intrinsic_repeat/run_tests.py \
  --candidate /absolute/path/to/immutable-combined-cli \
  --gfortran gfortran \
  --result /absolute/path/to/generic-repeat-results.json
```

The runner performs both `--check` and ordinary execution for every one of the
39 fixtures. It requires clean check output, exact successful stdout and empty
stderr, diagnostic-content matches, and distinct source/runtime exit status.
GNU expectations are 24 executions, three compile-only tests (negative runtime
count, unsupported subroutine-generic extension, unsupported EXTERNAL), and
12 expected compilation failures. It is wrong to call compile-only tests GNU
runtime matches, or to call a successful `--check` a successful execution.

## Native producer / adapter test, only in the authorized build lane

Do not use `fpm test --target` here. This FPM version builds/links the entire
auto-test set before restricting execution, which can exhaust the shared disk.
Central integration owns this direct-link contract:

1. Read the current app/main entry in `build/compile_commands.json` from the
   authorized combined build. Reuse that exact compiler, profile, options and
   module-include paths, changing only the source and output locations to
   compile `test/test_generic_intrinsic_repeat.f90` into a separate temporary
   object. Do not rebuild the application or the auto-test set.
2. Link that object against the shared library produced from the same current
   static archive and matching link/runtime flags. Never mix metadata modules,
   objects, archives or libraries from different builds.
3. Execute the linked native test and capture the exact command, statuses,
   stdout/stderr, and hashes of the test source and linked library.

Expected output includes
`PASS: generic/intrinsic REPEAT producer and adapter assertions: 23` (list-
directed spacing may differ). The 23 assertions cover producer metadata,
ordinary adapter acceptance, four corruptions, matching user-generic priority,
and rejection of a forged intrinsic substitution for that matching generic.
Central integration reports all 23 assertions passing for the combined preview. Exact compile
and link argv must come from central integration's current build evidence, not
from stale flags copied into this document.

## Scope

Original raw CRLF bodies from lines 1041–1048 and 2096–2118 are unchanged.
Their small harness is not a complete-utilities execution. Run the existing
full-source gate audit separately to discover the next first-stage diagnostic;
retain original line/column, exit status, stdout and stderr. Do not edit the
utilities source to make the focused assertions pass.
