# Honor declaration PUBLIC/PRIVATE in module resolution

The scoped binding resolver previously applied standalone accessibility lists
and derived-type header attributes, but ignored intrinsic declaration attributes.
Under a PRIVATE module default, a PUBLIC scalar could be unresolved and an
exported array subscript could be rejected as an external function reference.
Conversely a PRIVATE declaration in a public module must not be exported.

Read each matching declaration's exact accessibility attribute, including all
names in multi-declarations. Existing independent interpreter access checks,
USE ONLY rules and declaration identity checks remain in place. The semantic
explicit-interface checker already consumes this resolver, so it now recognizes
the correctly exported array without disabling any semantic validation pass.

Apply after patches 0001–0033. Focused coverage is in test/test_module_data_producer.f90
and tests/mutable_modules (PUBLIC/PRIVATE attributes, multi-declarators and array
references). The full standalone upstream FortFront suite has not been run.
