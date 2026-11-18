# Debug build profiles

The portable default remains `python3 scripts/verify.py`: ordinary `fpm --profile debug` for the app, every native test, and executable selection. Windows execution is not yet validated.

The optional Linux GNU split-debug mode uses `python3 scripts/verify.py --split-debug`; the complete 0.45 certification combines it with `--shared-native` as described below. Every FPM build/test/run invocation adds only `--flag -gsplit-dwarf`. FPM retains `-g`, bounds checks, array-temporary checks, backtraces, implicit-none checks, warnings and the same optimization/default language semantics. Separate `.dwo` files retain DWARF debug information instead of copying the same large library debug data into every native test executable. This is not stripping or deleting debug information. Preserve the complete build tree, including `.dwo` files, for debugging.

The option is explicitly rejected outside Linux. It is an optional verification storage strategy, not a source requirement or a runtime feature. The release evidence records actual compiler commands, successful runtime-check probes, native/source results and executable identities. Each initial clean build extracts a recorded source archive into a new tree with an empty cache. Any later test-only rerun and cache reuse are reported explicitly, not described as another empty-cache build.

## Shared native verification on Linux

The 0.45 clean certification uses `python3 scripts/verify.py --split-debug --shared-native` because repeated static copies of the roughly 19 MiB interpreter code/data do not fit the verification workspace. The app remains normally statically linked to the FPM archive. Native tests use one shared library linked from that exact unchanged PIC archive. No compiler optimization, runtime check, source, or assertion is removed.

FPM's nonbuilding `--tests --list --dump` enumerates every native program and supplies its exact compile command. The verifier executes those commands unchanged, checks the complete source inventory, links all resulting test objects to the shared library with a relative runtime search path, and runs every program separately. Selected new and historical native programs are additionally linked statically from the same test object and archive; status, stdout and stderr must match exactly. Shared and static binaries are intentionally different, not claimed byte-identical. Commands, source/object/library/executable hashes, output streams and comparisons are retained under `build/verification_shared_native`.

The ordinary portable command still uses `fpm test --profile debug` without this option. Both specialized options reject unvalidated operating systems. All generated objects, separate debug information, test executables and shared libraries are preserved; this strategy does not delete completed tests or weaken the aggregate.

The initial integrated native preview exposed a new process-query test assumption that the current directory fits 80 characters. Both link modes failed the same assertion in the 86-character staging path. A separate test-only correction widens that test’s CWD buffer to the existing 65536-character contract cap, leaving name buffers and short/zero/overflow policy cases unchanged. The original failing source/object/executables and outputs are retained. This is a test environment correction, not a production implementation or linkage change. Final clean verification is performed after it.

## 0.46 receipt hardening

The same Linux split-debug/shared-native profile is retained. The verifier invalidates any stale success before discovery, records failures from subprocess launch, exit, timeout and archive rechecks, and publishes success only after the unchanged archive has been rehashed. Unsupported extra linker inputs and known disabling flag overrides are rejected rather than silently rewritten. These guards have synthetic adversarial tests; the release report separately records the complete clean execution.

The initial 0.46 verification tree was extracted from its recorded source-test ZIP into a new directory with spaces under `/tmp`, on a separate filesystem, and built from an empty cache. Its first aggregate found stale historical MAXLOC/SHAPE expectations. After test-only corrections, the complete official verifier ran again from the start using the unchanged clean-built code and CLI. That successful rerun was not a second empty-cache build. The initial failure, overlay and both archive identities remain preserved.

The 0.47 initial clean run again starts from an empty cache and its own exact source-test ZIP. Its final report records the actual outcome and any subsequent rerun, rather than inheriting an earlier success claim. Direct CLIs, logs, receipts and verified cache archives remain preserved persistently before approved reclamation. `/tmp` changes storage location, not language semantics or runtime checks.
