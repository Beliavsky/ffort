# 0.49 bounded changes

- Mixed initialized/uninitialized scalar derived-component declarations and fixed-length default CHARACTER fields. Undefined fields remain undefined and copies own their storage. Record-owned CHARACTER payloads have conservative admission and separate output-staging limits, not a global heap or sandbox guarantee. See [defaults](DERIVED-DEFAULTS.md), [grouped declarations](../tests/derived_mixed/README.md), and [CHARACTER fields](../tests/character_components/README.md).
- Whole scalar INTEGER stdout-unit names are evaluated once; only the processor output unit is admitted. No arbitrary file output. See [runtime units](../tests/runtime_output_unit/README.md).
- Function generic REPEAT tries valid user specifics first and falls back to the supported intrinsic signature only on no match. See [generic REPEAT](GENERIC_INTRINSIC_REPEAT.md).
- Slash format edits preserve staged records, positioning and atomic error behavior; bounded scalar internal/child-write restrictions remain explicit. The unchanged BTEST demo passes all 24 records byte-exact with GNU in the integrated profile. See [slash editing](../tests/slash_formats/README.md).
- LEADZ accepts INTEGER kinds 4/8 and returns default INTEGER, with rank 1–3 and independent metadata/runtime guards. See [LEADZ](LEADZ.md).

The exact one-byte-adapted full utility checks/runs only to 2376:11, array-element internal WRITE in `integer_labels`. It is not a full interpreter pass. The untouched original still hits its existing 9329:55 array storage cap. The existing 100,000,000-step xmix invocation and actionable configured-step diagnostic are preserved.

The final [verification report](VERIFICATION.md) is generated from the actual clean aggregate and independent survey; focused feature/composition outcomes are not a substitute. Windows and the standalone upstream frontend suite are not claimed tested.
