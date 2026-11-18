# Zero-width F output

F0.d output supports finite REAL(kind=4) and REAL(kind=8), with decimal precision d from 0 through 1024. The processor chooses enough field width for the value; no leading field padding is added. Existing host rounding and sign behavior is retained. Literal and runtime format strings, repeated/grouped/unlimited formats, PRINT and supported internal WRITE destinations use the same checked formatter.

F0 uses its own bounded 1,340-character scratch buffer. At most 309 integer digits, a sign, a decimal point and 1,024 decimal places are needed for supported finite REAL(8). Existing I0/G0 and positive-width paths keep their previous 1,024-character scratch boundary. The 65,536-character staged-record bound, operation limits, type checks, unsupported format controls and other zero-width restrictions are unchanged. Nonfinite values are rejected; forged REAL4 parameter-cache values outside the finite REAL4 range are rejected before narrowing.

## Focused evidence

On the central 0.54 preview, strict 40-case checking passed: 27 GNU execution/output agreements, 10 static candidate rejections and 3 runtime candidate rejections. The latter 13 boundaries are not claimed to match GNU rejection behavior. Each case ran --check and execution, and each positive also compiled/executed with GNU. Full streams, exact diagnostics, immutable source/output hashes, executable/compiler/runtime identities and independent review are retained under tests/fzero_formats/evidence.

The dedicated native test passed 43 assertions, including forged cached values, repeated failures/recovery and finite boundaries. The older numerical-runtime test had one obsolete F0.4-rejection expectation; changing only its expected Boolean restored its complete prior 124-byte stdout, empty stderr and zero status. Original source/failure and the narrow migration are preserved separately.

These are focused checks, not a claim of complete release certification. GNU/Linux was tested. The Python scripts use portable APIs, but Windows execution and host-specific output differences remain unverified.

## Maintained verification

The portable verifier runs the runner self-tests and tests/fzero_formats/run_tests.py with its selected executable/compiler and project version. The adapter pins the current executable, runtime source and compiler for the invocation; run_strict.py independently enforces these hashes and the fixed fixture manifest before and after operations. An explicit --compiler-binary may identify an underlying compiler when --gfortran names a wrapper; otherwise only the supplied compiler-driver file is independently pinned, without claiming a distinct backend identity.

Receipts use new exclusive files beneath verification/fzero_formats/run-* by default. They never overwrite earlier evidence. --result may choose another new file outside the fixture directory. The initial certified-focused receipt additionally pins both the local compiler wrapper and actual compiler binary. Every subprocess within the strict runner has a 20-second timeout and each case uses its own temporary working directory.

## Composed substring-support expectation migration

When array-element substring support joined the preview, the unchanged attached_s03_chars program advanced from its former static rejection to successful execution. The first run with the original 40 expectations recorded 39 passes and that one mismatch; it is retained unchanged. Independent GNU and candidate executions then produced identical 133-byte output. Only this case’s expected stage/output and the adapter’s fixed manifest hash were promoted; all 40 source files and the other 39 rows remained byte-identical.

The composed suite passed all 40 cases: 28 GNU execution/output agreements, 9 static candidate boundaries and 3 runtime candidate boundaries. All 136 operations and the original 27-agreement evidence remain distinct in the preserved receipts. The verifier hook and native 43 test are unchanged. This expectation migration does not modify runtime/core sources or claim broader release certification.
