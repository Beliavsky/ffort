program probe
implicit none
logical :: a(-2:2),b(5:9)
a(-2)=.false.
a(-1)=.false.
a(0)=.false.
a(1)=.false.
a(2)=.true.
b(5)=.false.
b(6)=.false.
b(7)=.false.
b(8)=.true.
b(9)=.true.
a=(a.neqv.b).eqv.a(2)
b=.not.a.or.b
a=(a.neqv.b).eqv.a(1)
b=.not.a.or.b
a=(a.neqv.b).eqv.a(0)
b=.not.a.or.b
a=(a.neqv.b).eqv.a(-1)
b=.not.a.or.b
a=(a.neqv.b).eqv.a(1)
b=.not.a.or.b
print *,a,b
end program probe
