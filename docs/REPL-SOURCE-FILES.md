# Bounded REPL source files (development preview)

`.save filename` writes the current standard-Fortran wrapper and body to a new
file. `.save` without a filename selects the first unused `main.f90`,
`main1.f90`, etc., up to `main99999.f90`. Every create uses `STATUS='NEW'`;
existing files are never overwritten. There is no overwrite option yet.
Filenames with spaces must be single- or double-quoted. Embedded matching quotes,
control bytes and extra options are rejected. No shell is invoked.

`.load filename` accepts the exact `program repl_session` / `implicit none` /
`end program repl_session` wrapper emitted by this REPL. Windows CRLF is
normalized to LF. The existing bounded C input loader rejects nonregular files
before reading; final-path symlinks and Windows reparse points are unsupported.
Linux FIFO/device/directory/symlink rejections are tested. Other complete programs/modules, raw bodies, state snapshots
and binary sidecars are not supported in this increment. The input must obey
existing byte, line-length and line-count limits. NUL and isolated CR bytes are
rejected. A missing final LF is rejected. The loaded body is not compiled or
executed, allowing incomplete drafts saved by this REPL to round-trip. Later
execution still uses the ordinary parser, frontend verification and runtime
limits. A successful load replaces the buffer and clears retained values, RNG
state, frozen declarations and error state. A failed load changes none of them.

`.quit` autosaves a nonempty body to the first unused `main*.f90`, without
executing pending source or expressions. A save failure reports the error and
keeps the REPL open and buffer intact. `.quit!` exits without saving. Empty-buffer
`.quit` writes nothing. EOF still neither runs nor saves, a deliberate documented
difference from the inspected ofort implementation. `q`/`quit` aliases are not
implemented here.

Saved files contain source, not the values of variables or expression history.
Loading one does not restore a live session; `.save-state` and `.load-state`
remain separate future features. A write/close failure can leave a partial new
file; it is reported, not silently deleted or retried as an overwrite.

These host source-file commands are REPL UI features. They do not grant the
interpreted Fortran program general filesystem access. Validation is focused
Linux testing; Windows execution and full ofort parity are not claimed.
