program probe
implicit none
logical :: a(-4:0)
a(-4)=.true.
a(-3)=.false.
a(-2)=.false.
a(-1)=.false.
a(0)=.true.
a(-4)=a(-1).neqv.(.not.a(-3))
a(-2)=a(-2).neqv.(.not.a(-1))
a(-2)=a(-4).neqv.(.not.a(-2))
a(0)=a(-2).neqv.(.not.a(-4))
a(-4)=a(-2).neqv.(.not.a(-2))
a(-2)=a(-4).neqv.(.not.a(0))
a(-2)=a(-1).neqv.(.not.a(-4))
a(-2)=a(-3).neqv.(.not.a(-4))
a(-4)=a(0).neqv.(.not.a(-4))
a(-4)=a(-3).neqv.(.not.a(0))
a(-2)=a(-2).neqv.(.not.a(0))
a(-2)=a(-4).neqv.(.not.a(-1))
print *,a(-4),a(-3),a(-2),a(-1),a(0)
end program probe
