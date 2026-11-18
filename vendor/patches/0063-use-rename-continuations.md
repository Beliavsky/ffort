# 0063: Continued USE-list comment trivia

Local MIT-licensed correction to the pinned FortFront producer. Existing USE
alias AST pairs and named-kind resolution are retained. The parser now skips
retained comments and whitespace while reading USE metadata, including local
names, arrows, remote names and module nature/ONLY clauses. It never consumes a
remaining logical newline, so a missing continuation marker is not repaired.

The adapter remains responsible for the interpreter's bounded explicit
intrinsic ISO_FORTRAN_ENV ONLY contract. No nonintrinsic renaming or unsupported
kind is admitted by this producer patch. Six independent strict producer inputs
cover continued/trailing comments, exact alias identities and kind metadata,
and a missing-marker rejection.

Based on the certified 0.37 vendor tree through patch 0062. Apply the matching
patch at the vendor root with `patch --fuzz=0 -p1`. No registry count changes.
