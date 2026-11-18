# Internal WRITE element native handoff

Use the central shared app/library cache for this implementation. Do not run
`fpm test --target`: this workspace's FPM builds/links the entire auto-test set
before restricting execution and can exhaust disk space.

Compile each source by taking the exact current `app/main.f90` command from
`compile_commands.json` and substituting only the native source and its object
output. Preserve all profile flags and module search paths. Link directly to
the shared library built from that same current static archive. Retain the
full compile/link argv, module paths, source/library/archive hashes, statuses
and both streams. Do not mix module files or an archive from a previous build.

Sources and expected assertion totals:

- `test/test_internal_write_element.f90`: 119.
- `test/test_internal_write_element_hardening.f90`: 32.
- `test/test_internal_write_element_derived_guard.f90`: 10.
- `test/test_internal_write_loop_parents.f90`: 24.

All four were centrally compiled, linked and run successfully against the
corrected preview, SHA-256
`3e9c191de0f548e9dc8fc189c3d579e4fde4dbc2617c0b43170add660ca04a19`.
The matching archive SHA-256 is
`42af72ee32bacbb8a59aff162abde4a9669c4959082e8b04829ede0cde90a726`;
the shared-library SHA-256 is
`496a0f9cc628281f3380be30812c29bcf63216b2572088f06bf22930be4e6a70`.
Every owned compile/link/run status was zero; successful runtime stderr was
empty. The 185 assertions are focused native evidence, not a claim that the
whole release or utility program is certified.
