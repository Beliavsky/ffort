# GNU14.2 empty concatenation length discrepancy

GNU Fortran (Debian14.2.0-19)14.2.0 was the tested oracle. This is a valid Fortran
source with a known GNU compile defect, explicitly separated from ordinary
invalid-source rejections and successful differential executions in results.json.

## Source

```fortran
implicit none
character(*),parameter::a(0)=[character(3)::]//trim("a  ")
character(*),parameter::b(1)=reshape(a,[1],pad=["abcd"])
print '(a)',b//":"
end
```

## Rule

[J3/24-007](https://j3-fortran.org/doc/year/24/24-007.pdf#page=184), section10.1.9.3
paragraph4, gives CHARACTER concatenation the sum of its operand lengths;
section10.1.10 paragraph2 applies scalar expansion to arrays, including arrays
with zero elements. Thus a has zero elements of length4, and b receives the
length-4 PAD value. The independent expected output is `abcd:` followed by newline.
This inference from the standard does not depend on the compiler's observed value.

## Reproduction

From the repository root (substitute the compiler/executable paths as needed):

```sh
gfortran -std=f2018 -pedantic-errors -fcheck=all -O0 tests/character_parameters/cases/empty_concat_element_length.f90 -o strict
```

Exit status 1. Diagnostic:

```text
tests/character_parameters/cases/empty_concat_element_length.f90:3:48:

    3 | character(*),parameter::b(1)=reshape(a,[1],pad=["abcd"])
      |                                                1
Error: The CHARACTER elements of the array constructor at (1) must have the same length (4/3)
```

Without strict flags:

```sh
gfortran tests/character_parameters/cases/empty_concat_element_length.f90 -o ordinary
./ordinary
```

Compile/run status 0/0, stdout:

```text
abc:
```

Interpreter:

```sh
fortfront-interpreter tests/character_parameters/cases/empty_concat_element_length.f90
```

Status 0, stdout:

```text
abcd:
```

The same GNU empty-concatenation length3 appears with a literal `"a"` instead of
TRIM. Nonempty concatenation gives length4. The interpreter preserves the
standard-defined sum rather than adopting the oracle's empty-array behavior.
The runner tolerates only the recorded GNU compile diagnostic for this case;
if GNU accepts it, correct runtime output is required instead.
