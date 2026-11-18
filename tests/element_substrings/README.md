# Scalar array-element CHARACTER substrings

Run `python tests/element_substrings/run_strict.py --candidate PATH --expected-sha SHA256 --gfortran PATH_TO_GFORTRAN --gnu-sha GNU_SHA256 --output NEW.json`. The output must not already exist. Run harness tests with `python -m unittest discover -s tests/element_substrings -p test_strict.py`.

The 24 cases preserve the original21 attempt bytes and add three separately named supported-context controls. Expected results are pinned, not learned by the runner. The exact Claude s03_chars attachment is retained. Its complete output agrees byte-for-byte with GNU.

Reads and assignments of scalar substrings of rank1–3 CHARACTER elements are covered, including bounds, lower bounds, padding/truncation, overlap, descriptor LEN/KIND, PARAMETER arrays, full initialization, undefined reads and partial writes. Bare INTENT(IN) inputs conservatively reserve the entire array against another writable actual; parenthesized inputs copy values first. Sections/gathers as substring bases, writable substring actuals, and substring internal-file targets remain excluded.

Original index_once and rhs_shrinks_target_safety use module writes in ordinary functions, an existing effect-policy rejection measured on certified0.53. Separate IMPURE ELEMENTAL controls test supported effects without relaxing that policy. The original partial_undefined implicit assignment-only main hits an existing producer program-recognition boundary, reproduced with an ordinary element assignment on0.53; the explicitly named-main counterpart tests the intended runtime guard. These are valid-source subset limitations, not invalid Fortran. Original source and first failed results are retained, not rewritten into successful tests.

GNU executes16 cases and compiles8 only. Undefined reads, invalid bounds, and the target-shrink defensive test are never executed with GNU. The supported index-effect control also matches GNU with `-O2 -fcheck=all`; target-shrink is compile-only under both profiles. No test depends on universal logical short-circuit evaluation. Target-shrink rejection prevents unsafe slicing; it does not claim arbitrary effects are standard-valid or rolled back.

Fifth preview14a7 passes24 strict source contracts and native339 assertions. The first preview's adapter assignment-target failure is retained. Source-contract outcomes,44 Python test methods and339 native assertions are distinct units. Full release certification remains central.

The r3 runner copies the reviewed INQUIRE R5-exact descriptor-relative exclusive-output and raw process-capture helpers. The pure validator requires canonical raw Base64, byte hashes and strict UTF-8 agreement, exact stage types/commands/cwds, pinned GNU/candidate launchers and banners before/after, unchanged complete policy/source inventories and exact24-case bijection. All24 GNU compilations require empty stdout/stderr; only16 authorized cases execute. GNU profile is bundled and included in the policy inventory. Original r1 receipts are preserved historical observations, not r3 certification.

The r3 pure reducer also binds its caller-supplied manifest exactly (including JSON value types) to the pinned on-disk contract and separately checks actual fixture bytes against each pinned source SHA. Rebinding receipt inventory maps cannot authorize changed source or expected output.
