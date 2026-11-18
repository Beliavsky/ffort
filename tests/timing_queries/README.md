# Bounded host timing inquiries

`SYSTEM_CLOCK` accepts optional COUNT, COUNT_RATE and COUNT_MAX, positionally or
by keyword. `CPU_TIME` requires TIME (also accepted as a keyword). Every supplied
output must be a distinct, writable, whole scalar. INTEGER kinds 4/8 are supported
for COUNT/MAX and integer RATE; REAL kinds 4/8 are supported for RATE and TIME.
Module variables, ordinary locals, writable dummies, supported captured locals and
saved scalars retain ordinary binding, presence, alias and effect checks. Values
need not previously be defined. Arrays/elements, POINTER, ALLOCATABLE, PARAMETER,
INTENT(IN), active DO counters and overlapping outputs are outside this slice.
Source procedures and generics named like the intrinsics retain precedence.

All supplied INTEGER arguments must have the same kind, following F2023
16.9.202. GNU 14's accepted mixed-kind forms are recorded as compile-only subset
boundaries, not GNU rejections. REAL COUNT_RATE may have a different kind. The
interpreter chooses the kind-4 host clock if any present output has kind 4, or if
all outputs are omitted; otherwise it chooses the kind-8 host clock. This matches
the observed GNU kind-4/kind-8 selection on the verification host, but rates,
maximums and counts themselves are processor-dependent. Consistently use the
same argument types/kinds across calls intended to measure an interval.

A forwarded absent OPTIONAL SYSTEM_CLOCK output remains absent; CPU_TIME's TIME
must be present. GNU 14.2 crashes when forwarding all three absent optional
outputs in the retained probe. That case has a separately labeled specification
oracle (F2018 15.5.2.12p4), with GNU compilation only. No successful GNU execution
agreement is claimed for it. A SIMPLE probe is skipped by GNU 14, which does not
implement SIMPLE. PURE/SIMPLE (including transitive runtime callers), concurrent
body restrictions, module/host mutation rules and the shared execution budget
remain enforced. Each timing call charges 64 work units before querying the host.

## Samples and output safety

Ordinary interpreted execution always obtains actual host intrinsic samples.
There is no source/CLI test clock, embedding callback, sleep, environment-variable
lookup or process launch. The small `fi_clock` helper validates a typed request and
sample, stages all outputs, then the runtime commits them together. The same
helper is exercised directly by deterministic native tests without replacing the
ordinary clock path. Malformed metadata, invalid ranges, nonfinite values and
narrowing overflow fail before any output is defined.

Available SYSTEM_CLOCK counts are in [0, COUNT_MAX], with positive COUNT_RATE;
the count wraps to zero after COUNT_MAX. Unavailable clocks use `-HUGE(COUNT)`,
zero RATE and zero MAX. An unavailable sentinel is mapped to the actual COUNT
kind even when REAL RATE selected a smaller clock. CPU_TIME preserves finite
nonnegative elapsed CPU seconds or a finite negative unavailable sentinel.
REAL(4) results are rounded at REAL(4) precision; an unavailable negative sample
cannot silently round into a nonnegative value. Rates are approximate when REAL.

## Evidence and running

```sh
python3 tests/timing_queries/test_runner.py
python3 tests/timing_queries/run_tests.py --candidate /path/to/fortfront-interpreter --gfortran gfortran
```

The original M_intrinsics `demo_cpu_time.f90` and `demo_system_clock.f90` are
byte-preserved (commit and hashes in provenance.json; license retained).
CPU_TIME's three elapsed-time records are validated as finite observations,
separately for each implementation, never compared byte-for-byte. The original
SYSTEM_CLOCK program loops almost HUGE(default INTEGER) times. It is compiled
by GNU, checked by the interpreter, and deliberately stopped with a bounded
interpreter work budget after validating its initial clock reports. This is not
a completed execution or GNU runtime agreement for that program.

Four unchanged CRLF procedure bodies from xutilities are wrapped with only their
required module declarations and a small test driver: init_wall_time, set_time,
wall_time_elapsed and time_elapsed. The first writes the original module variable
old_time_. Exact line ranges and hashes are retained. The complete utility source
is tested separately with the constructor feature; these slices alone do not
claim full-utility support.

Primary specifications: [F2018 working draft, 16.9.57, 16.9.186 and 15.5.2.12](https://j3-fortran.org/doc/year/18/18-007r1.pdf)
and [F2023 working draft, 16.9.202](https://j3-fortran.org/doc/year/23/23-007r1.pdf).
