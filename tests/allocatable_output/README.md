# Allocatable and formatted-output integration

These seven synthetic fixtures combine the new features. They are not copies of
the original utilities or full upstream examples. Successful cases compare every
stdout byte with GNU Fortran, including record boundaries and trailing blanks.
They cover allocatable INTENT(OUT)/INOUT descriptors, function results, PACK,
mutable module rank-two arrays, reversed sections, reduction/location intrinsics,
REAL(8) hyperbolics, zero extents, reallocation, and scalar internal WRITE. Two
interpreter-only cases require failed output statements to produce no partial
records when a later array is undefined or unallocated.
