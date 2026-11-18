# Real hyperbolic intrinsic metadata

Register SINH, COSH and TANH as real intrinsics in the strict frontend and propagate
operand kind and elemental rank through the existing type-query rules. The
interpreter separately validates its supported REAL(4/8), rank-zero/two boundary;
no semantic fallback or relaxed strict-mode check is introduced.

Apply after the 0.20 patch series through 0030. This patch is independent of the
array-result work and intentionally uses number 0032. Native mutation coverage is
in `test/test_hyperbolic_intrinsics.f90`; GNU comparisons and source rejections are
in `tests/hyperbolic_intrinsics`. The exact original `sech` utility slice adds an
end-to-end user-source regression.
