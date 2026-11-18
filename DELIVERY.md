# REPL bare-value fix development preview

One complete-source checkpoint. Changes are applied; no manual patching is required.
Current README and PREVIEW-STATUS.json supersede historical delivery claims below.
No new full native suite, Windows execution or clean maintained-suite certification is claimed.

---

# Internal READ sections development preview

One complete-source development checkpoint. Current PREVIEW-STATUS.json and
README take precedence over historical delivery claims below. No Windows or
clean maintained-suite certification.

---

# Array-intrinsics development preview

One complete-source development checkpoint. Current PREVIEW-STATUS.json and
README take precedence over historical delivery claims below. No Windows or
clean maintained-suite certification.

---

# SELECT development preview

One complete-source development checkpoint. Current PREVIEW-STATUS.json and
README take precedence over historical delivery claims below. No Windows or
clean maintained-suite certification.

---

# Inspection development preview

One complete-source development checkpoint. Current PREVIEW-STATUS.json and
README take precedence over historical delivery claims below. No Windows or
clean maintained-suite certification.

---

# Development preview delivery

This archive is one complete-source development checkpoint, not the certified
0.56 three-part delivery described historically below. Its root is
`fortfront-repl-loop-control-preview/`. Current preview status and evidence take
precedence over historical release claims. No Windows execution or clean
maintained-suite certification is claimed.

---

# Development preview delivery

This archive is one complete-source development checkpoint, not the certified
0.56 three-part delivery described historically below. Its root is
`fortfront-repl-growth-preview/`. Current preview status and evidence take
precedence over historical release claims. No Windows execution or clean
maintained-suite certification is claimed.

---

# Development preview delivery

This archive is one complete-source development checkpoint, not the certified
0.56 three-part delivery described historically below. Its root is
`fortfront-repl-expressions-preview/`. Current preview status and evidence take
precedence over historical release claims. No Windows execution or clean
maintained-suite certification is claimed.

---

# Development preview delivery

This archive is one complete-source development checkpoint, not the certified
0.56 three-part delivery described historically below. Its root is
`fortfront-repl-loops-preview/`. Current preview status and evidence take
precedence over historical release claims. No Windows execution or clean
maintained-suite certification is claimed.

---

# Development preview delivery

This archive is one complete-source development checkpoint, not the certified
0.56 three-part delivery described historically below. Its root is
`fortfront-repl-if-arrays-preview/`. Current preview status and evidence take
precedence over historical release claims. No Windows execution or clean
maintained-suite certification is claimed.

---

# FortFront 0.56.0 three-part delivery contract

The delivery contract requires three disjoint ZIP parts with a common `fortfront-interpreter-0.56.0/` root:

1. Source, tests, fixtures, examples and manuals, build-ready independently of proof archives, subject to documented toolchain prerequisites.
2. Current 0.56 verification evidence under `docs/verification/0.56.0/`.
3. Historical 0.55 and earlier verification evidence under the other `docs/verification/` version directories.

Extract all three into the same parent directory to resolve historical and current proof links. No member may overlap across parts. Each part must remain below 20 MiB; actual sizes, filenames, SHA-256 values, member manifests and byte/mode reconstruction are final delivery gates, verified by the final delivery receipt, not inferred from clean-test success.

## Fresh outputs are mandatory

Run maintained verification from a fresh extraction and fresh build cache with every exclusive result/evidence target absent. Never overwrite retained receipts or relax exclusive-output guards. Historical receipts stay in proof directories, and current measured outputs are exported to the current-proof part rather than included at exclusive source result paths. A focused pass or interrupted full run does not certify a fresh successor.

## Historical delivered 0.55 delivery instructions (verbatim)

The following describes the delivered 0.55 pair, not the 0.56 three-part layout.

# FortFront 0.55.0 source and verification delivery

- `fortfront-interpreter-0.55.0.zip`: source, fixtures, tests, examples and manuals.
- `fortfront-interpreter-0.55.0-verification.zip`: all `docs/verification/` evidence, including historical 0.54 proof and current 0.55 measurements.

Extract both archives into the same parent directory. Both use `fortfront-interpreter-0.55.0/` as their root. Their member sets are disjoint, so the companion adds proof rather than overwriting main-source files. The main source remains build-ready independently, subject to the documented toolchain prerequisites. Relative proof links require both archives. Each part has a SHA-256 member manifest; the external delivery receipt records final sizes and hashes. Actual archive size and reconstruction verification are release gates separate from the clean source measurements.

## Fresh verification outputs

Run maintained verification from a fresh extraction with a fresh build cache and absent exclusive-output targets. Do not rerun over retained outputs or relax exclusive-output guards. Five historical INQUIRE harness/result, substring and release054-integration receipts are retained under `docs/verification/0.55.0/historical-exclusive-receipts/`, preserving their original relative paths, bytes and modes. Current receipts live only in the companion exports; the corresponding source output paths and READ-element result/raw-evidence targets remain absent in the main ZIP. A stopped run does not certify a successor extraction.

## Historical 0.54 delivery instructions

The following text is preserved verbatim and describes the delivered 0.54 pair, not current 0.55 artifacts.

# FortFront 0.54.0 delivery

Use both archives for the complete source-and-proof checkpoint:

- `fortfront-interpreter-0.54.0.zip`: complete source, tests, examples and manuals. It is build-ready without the companion, subject to the documented toolchain prerequisites.
- `fortfront-interpreter-0.54.0-verification.zip`: all current evidence under `docs/verification/0.54.0/`.

Each ZIP is below 20 MiB. Extract both into the same parent directory. Both use `fortfront-interpreter-0.54.0/` as their root, and their member sets are disjoint: the companion adds files rather than overwriting the main archive.

The main `MANIFEST.sha256` and companion `docs/verification/0.54.0/MANIFEST.sha256` both use paths relative to that common project root. External `fortfront-interpreter-0.54.0-delivery.json` and `fortfront-interpreter-0.54.0-SHA256SUMS.txt` bind the two archive filenames, sizes and SHA-256 checksums; final archive hashes are deliberately not embedded in the archives themselves.

Current proof links resolve after extracting the companion. Start with [verification](docs/VERIFICATION.md), [measured summary](docs/verification/0.54.0/final-summary.json), [post-clean source audit](docs/verification/0.54.0/source-audit.json) and [artifact index](docs/verification/0.54.0/ARTIFACTS.json).

The measured certification profile is Linux GNU Fortran 14.2 with the recorded official debug and split-DWARF flags. This is not a claim that the verification runners have passed on arbitrary compilers or operating systems. Source/FPM build portability and successful execution of this exact verification profile are distinct claims. No compiled interpreter or GNU executables are included in the delivery ZIPs.
