program probe
implicit none
logical :: a(3), b(3)
a(1)=.true.
a(2)=.false.
a(3)=.true.
b(1)=.false.
b(2)=.false.
b(3)=.true.
print *, .not.a,a.and.b,a.or.b,a.eqv.b,a.neqv.b
end program probe
