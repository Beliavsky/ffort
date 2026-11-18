program probe
implicit none
logical :: a(3), b(3)
a(1)=.true.
a(2)=.false.
a(3)=.true.
b=.false..neqv.a
print *, b,a.and..true.,.false..or.a,.true..eqv.a
end program probe
