# ffort

ffort is an experimental Fortran interpreter with an interactive REPL and a
command-line runner for Fortran source files. Use it to explore expressions,
try small programs and inspect values without compiling each program to an
executable.

**Built with [FortFront](https://github.com/lazy-fortran/fortfront).** Credit goes
to Christopher Albert and the FortFront contributors for the frontend library
that provides parsing, semantic analysis and AST APIs. ffort vendors a pinned,
locally patched copy of FortFront and uses it to cross-check source before
execution. The interpreter and runtime are separate work; see the
[third-party notices](THIRD_PARTY_NOTICES.md) and
[FortFront integration notes](docs/FRONTEND.md) for attribution and local changes.

## What it supports

- An interactive REPL with bare expression queries, retained values, source
  editing, inspection commands, and source saving and loading.
- Batch execution and check-only validation of supported Fortran source.
- INTEGER, REAL, LOGICAL and CHARACTER values; supported array operations through
  rank three in batch mode; and a narrower rank-one subset in retained REPL sessions.
- Control flow, procedures, modules, intrinsics and formatted I/O within the
  documented subset.
- Runtime checks for undefined values, array bounds, arithmetic errors and
  execution limits.

This is a development preview implementing a bounded subset of Fortran.
Unsupported constructs are rejected. Batch execution supports more constructs
than retained REPL sessions; consult the feature guides for exact restrictions.

## Build

Install GNU Fortran with Fortran 2018 support, a compatible C compiler, and the
Fortran Package Manager (`fpm`). Put them on your `PATH`.
The FortFront library sources are included in this repository.

```sh
git clone https://github.com/Beliavsky/ffort.git
cd ffort
fpm build
```

The FPM executable target is named `fortfront-interpreter`. The same FPM commands
can be used from PowerShell with a matching Windows compiler toolchain. Recorded
verification primarily covers Linux; see the [verification records](docs/VERIFICATION.md)
for platform and checkpoint details.

## Run a program

```sh
fpm run fortfront-interpreter -- examples/sum_squares.f90
```

Check source without executing it:

```sh
fpm run fortfront-interpreter -- --check examples/sum_squares.f90
```

For longer computations, raise the default budget of 1,000,000 execution steps:

```sh
fpm run fortfront-interpreter -- --max-steps 10000000 examples/sum_squares.f90
```

More sample programs are in [examples](examples), including
[matrix multiplication](examples/matrix_multiply.f90),
[Black-Scholes pricing](examples/black_scholes.f90) and
[array operations](examples/array_intrinsics.f90).

## Use the REPL

```sh
fpm run fortfront-interpreter -- --repl
```

Enter declarations and statements for a program body, followed by expressions
to inspect their values:

```text
> integer :: n
> n = 5
> n*n
25
> n = n + 1
> n
6
> .quit!
```

Supported assignments and completed control-flow blocks execute as they are
entered. Queries retain values without replaying earlier output or random-number
effects. Declare arrays, named constants and explicitly kinded variables before
execution; adding declarations afterward has narrower rules.

| Command | Purpose |
| --- | --- |
| `.help` | Show commands and limits |
| `.vars` / `.info` | Inspect values and type information |
| `.shapes` / `.sizes` | Inspect arrays |
| `.list` | Show the buffered source |
| `.del` / `.ins` / `.rep` | Edit source lines |
| `.run` | Restart and execute the entire buffered program |
| `.clear` | Clear source and retained state |
| `.save file` / `.load file` | Save or load REPL source |
| `.quit` | Save to an unused `main*.f90` and exit |
| `.quit!` | Exit without saving |

Without a filename, a terminal starts the REPL; piped input is treated as batch
source unless `--repl` is specified. See the [REPL guide](docs/REPL.md) for
retained-session limits, editing rules and error recovery.

## Documentation

- [REPL behavior and supported subset](docs/REPL.md),
  [source editing](docs/REPL-EDITOR.md) and [source files](docs/REPL-SOURCE-FILES.md)
- [Arrays and memory limits](docs/ARRAY-LIMITS.md),
  [rank-three arrays](docs/RANK-THREE.md) and [source limits](docs/SOURCE-LIMITS.md)
- [FortFront integration and architecture](docs/FRONTEND.md)
- [Verification records](docs/VERIFICATION.md) and [changelog](CHANGELOG.md)
- [Development history and archived README](docs/DEVELOPMENT-HISTORY.md), including
  detailed preview notes, feature links and historical validation results

## Testing

Run the native Fortran regression tests:

```sh
fpm test
```

The independent differential suite also requires Python 3 and compares supported
programs with GNU Fortran:

```sh
python scripts/verify.py
```

Test results apply to the documented subsets and checkpoints; they do not imply
full Fortran conformance. Detailed results are in the
[verification records](docs/VERIFICATION.md).

## License

MIT. See [LICENSE](LICENSE). The vendored FortFront library is also MIT licensed;
its original notice is retained in [vendor/fortfront/LICENSE](vendor/fortfront/LICENSE).
See [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) for full attribution.
