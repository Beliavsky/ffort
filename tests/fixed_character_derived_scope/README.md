# Scoped fixed-CHARACTER argument metadata

This separate regression followup closes two public-IR validation gaps without
changing the earlier source fixtures or frozen patches.

Component/derived traversal permission is opened only by actual arguments of
fixed CHARACTER-returning user functions. Ordinary value operations retain their
existing support, including `ABS`, numeric `MAX` and `SUM` over a component.
Strict metadata/inquiry/bit/EOSHIFT dispatch resets that permission. Direct
component inquiry boundaries are unchanged. The permission check precedes memo
reuse; scoped and strict memo states are distinct, so a shared component or an
arithmetic ancestor cannot conceal a later restrictive inquiry edge.

Type-bound calls additionally require a scalar variable receiver whose expression
and declaration agree with the binding's type identity and first formal dummy.
Duplicating a type's schema/binding table does not make the original receiver an
instance of that duplicate type.

Nine source cases pass the final scoped candidate: three ordinary value-operation
successes, two strict KIND boundaries, two nested EOSHIFT context boundaries and two unchanged release047 EOSHIFT cases.
All stages agree with the certified 0.47 baseline. GNU executes the seven synthetic
programs; the two historical cases keep their existing compile-only policy.
The historical source and unit-27 input bytes are verified against their retained
upstream files. Explicit input bindings are used only during execution.

The final native program passes 48 assertions, including 33 metadata mutations
and shared-component/ancestor DAG checks. Native compile output retains GNU's
large local descriptor warning for the nonrecursive, sequential test helper;
no production warning or crash is hidden. Thirty harness checks and eight-file
generator replay pass. The prior 20-case regression suite remains unchanged and
passes the scoped candidate. Earlier candidates, diagnostics and native binaries
are retained. Central integration owns the complete clean release certificate.

```
python3 tests/fixed_character_derived_scope/self_test.py
python3 tests/fixed_character_derived_scope/check_generator.py
python3 tests/fixed_character_derived_scope/run_tests.py --candidate /path/to/cli --gfortran /path/to/gfortran
```

The two nested EOSHIFT fixtures are separately demonstrated to fail with the
certified 0.47 diagnostic, wrongly succeed on the initial derived-actual fix,
and fail again on the scoped correction. The additional native EOSHIFT probes
reuse the same component/ABS ancestor expression node as a strict SHIFT control
after a CHARACTER actual, directly exercising context-sensitive traversal.
The retained KIND-DAG tests establish rejection only, since an earlier local
KIND metadata guard can reject before memo traversal. No core change was needed
for this stronger evidence. All 726 historical cases pass the scoped candidate.
