program probe
implicit none
logical :: a(-2:2),b(5:9)
a(-2)=.true.
a(-1)=.true.
a(0)=.false.
a(1)=.false.
a(2)=.false.
b(5)=.true.
b(6)=.false.
b(7)=.true.
b(8)=.false.
b(9)=.false.
a=(a.neqv.b).eqv.a(0)
b=.not.a.or.b
a=(a.neqv.b).eqv.a(-1)
b=.not.a.or.b
a=(a.neqv.b).eqv.a(-1)
b=.not.a.or.b
a=(a.neqv.b).eqv.a(0)
b=.not.a.or.b
a=(a.neqv.b).eqv.a(-2)
b=.not.a.or.b
print *,a,b
end program probe
