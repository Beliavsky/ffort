program probe
implicit none
logical :: a(-5:-1)
a(-5)=.false.
a(-4)=.true.
a(-3)=.false.
a(-2)=.false.
a(-1)=.true.
a(-4)=a(-2).neqv.(.not.a(-4))
a(-1)=a(-5).neqv.(.not.a(-2))
a(-2)=a(-1).neqv.(.not.a(-1))
a(-1)=a(-5).neqv.(.not.a(-3))
a(-4)=a(-1).neqv.(.not.a(-1))
a(-5)=a(-3).neqv.(.not.a(-2))
a(-2)=a(-3).neqv.(.not.a(-1))
a(-4)=a(-3).neqv.(.not.a(-3))
a(-3)=a(-4).neqv.(.not.a(-4))
a(-3)=a(-3).neqv.(.not.a(-5))
a(-3)=a(-3).neqv.(.not.a(-1))
a(-4)=a(-2).neqv.(.not.a(-1))
print *,a(-5),a(-4),a(-3),a(-2),a(-1)
end program probe
