# OPTIONAL operator operands are invalid

All specific functions in a defined-operator interface require non-OPTIONAL
dummy operands, even if the interface is never referenced. These six fixtures
cover unary/binary forms, each binary operand position, and used/unused cases.
Both CLI paths must reject without output; GNU Fortran independently rejects
all six with its operator-operand diagnostic.

```
python3 tests/defined_operators/optional_operands/run_tests.py --candidate PATH_TO_INTERPRETER
```

The native `test_optional_operator_rejection` additionally uses coherent source
and IR OPTIONAL mutations to verify the adapter independently enforces the
operator-specific restriction. Its 18 assertions include six valid baselines,
six recognizer rejections and six independent adapter rejections.

This restriction applies only to operands of procedures registered in operator
interfaces. Ordinary optional functions and named generic interfaces are
unchanged and remain covered by the existing OPTIONAL/PRESENT corpus.
