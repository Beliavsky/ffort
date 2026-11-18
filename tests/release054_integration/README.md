# Independent 0.54 INQUIRE/F0/substring composition

The original 12-case INQUIRE-only stage keeps explicitly registered input names separate from host file discovery. The additive six-case stage composes that contract with the separately implemented F0.d and array-element substring features. Neither stage adds OPEN or host INQUIRE to interpreted sources.

The 12 source bodies were frozen before the first candidate observation. Seven GNU-executed positives cover READ/BACKSPACE and endfile state, a DO WHILE changing UNIT on the same INQUIRE instruction, internal WRITE to an array element, deferred-length CHARACTER/MOVE_ALLOC, assumed-length output dummies and exact padding, and an existing nonadvancing stdout record. Four GNU compile-only safety/subset cases preserve undefined UNIT, an unregistered stdout UNIT, module-owned NAME, and the ordinary-function transitive effect boundary. The PURE source is rejected by GNU as invalid. No undefined source is executed by GNU.

Two small input files and their exact spelling are pinned in `input-manifest.json`. Each invocation uses an isolated working directory. FortFront receives explicit `--input UNIT=relative-name` bindings. For GNU only, the single `! GNU_REGISTER_INPUT` marker becomes two explicit `OPEN(...,STATUS='OLD',ACTION='READ')` statements; no other source text is changed. Each raw adapted oracle and its hash are recorded. The provided spelling, including the space in `alpha input.dat`, is the name oracle, not an absolute/canonical path promise. GNU checked `-O0` and checked `-O2` profiles are separate receipts.

An unnamed registered API binding cannot be expressed through this CLI. This suite does not mislabel the unregistered stdout test as unnamed-API coverage; that contract requires the owner's native tests. A separate missing-path `--check` probe must succeed silently without opening or creating a file.

All comparisons are exact UTF-8 bytes, including padding, record endings, pending output prefixes, integer spelling, status, and source-located diagnostic. No numeric tolerance, float coercion or whitespace normalization is used. Compile-only/rejection profiles are not execution agreement. The harness rejects signals, timeout, host crash/ICE markers and corrupted stream types. It verifies fixture/input inventories and generator reproduction. No fixture depends on short-circuit `.and.`/`.or.` evaluation.

Initial INQUIRE-only preview `1e028b84` passed six positive executions but rejected the valid dummy-name procedure case at `7:0: FortFront adapter: missing statement`. It also stopped the ordinary-function effect case at that producer omission before reaching the intended runtime guard. These first outcomes and all original sources remain preserved outside the portable suite. They are genuine procedure-dispatch defects, not reclassified subset cases. That preserved first stage is not acceptance. Corrected INQUIRE-only preview `5c5b0811413b7dba9284c44839577c94ab3bcc6af2d27772cb048ff20f207e10` now passes all 12 strict candidate/GNU profiles, including the previously failed dummy case and the intended transitive runtime effect rejection. Only the five negative diagnostic metadata entries were pinned after preserving both raw observation sets; no source, category, expected stdout, GNU mode, or input bytes changed. The 47 adversarial harness methods pass. No application or native build was performed by this independent suite.

Run:

```sh
python3 tests/release054_integration/test_runner.py
python3 tests/release054_integration/run_tests.py --gfortran /path/to/gfortran --output /new/gnu.json
python3 tests/release054_integration/run_tests.py --gfortran /path/to/gfortran --optimize --output /new/gnu-O2.json
python3 tests/release054_integration/run_tests.py --candidate /path/to/fortfront-interpreter --expected-sha256 SHA --expected-version 0.54.0 --gfortran /path/to/gfortran --output /new/candidate.json
```

Existing result paths are never overwritten. `--observe` records raw outcomes but explicitly does not certify candidate expectations.

## Additive three-feature stage

The original 12 source bodies and every contract field remain unchanged. Six separately named sources add four positive compositions: F0 internal element-WRITE followed by substring access, registered INQUIRE plus F0 and substring assignment in a DO WHILE, distinct-array bare substring IN/OUT actuals, and parenthesized same-array snapshot input. Two compile-only GNU profiles retain conservative bare same-base writable-alias rejection and too-short internal F0 record rejection. Both candidate errors preserve exact prior output; the source test does not claim inspection of internal storage after the interpreter has terminated.

Before candidate execution, all18 GNU profiles passed checked O0 and O2. Fifth-preview14a7 first raw observations matched every intended category and byte output. Only the two new negative diagnostic objects were then pinned; all source bytes, expected stdout, GNU modes and original12 contracts were unchanged. The final strict18 run and52 harness methods are recorded separately. There are11 GNU execution comparisons,6 compile-only profiles and1 GNU rejection. No fixture uses assumed short-circuit logic. No external READ array-element feature is present or claimed.
