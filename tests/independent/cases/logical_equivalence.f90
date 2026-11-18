program probe
  implicit none
  logical :: a, b
  a=.true.
  b=.false.
  print *, a.eqv.b, a.neqv.b, a.eqv..true., a.or.b.eqv.a
end program probe
