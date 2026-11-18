program probe
implicit none
logical :: a(-3:1)
a(-3)=.false.
a(-2)=.false.
a(-1)=.true.
a(0)=.false.
a(1)=.false.
a(-1)=a(1).neqv.(.not.a(1))
a(-3)=a(0).neqv.(.not.a(-3))
a(-2)=a(-2).neqv.(.not.a(1))
a(-2)=a(-1).neqv.(.not.a(-1))
a(-1)=a(-2).neqv.(.not.a(-3))
a(-3)=a(1).neqv.(.not.a(1))
a(1)=a(-3).neqv.(.not.a(0))
a(-1)=a(1).neqv.(.not.a(0))
a(-2)=a(1).neqv.(.not.a(-3))
a(0)=a(-2).neqv.(.not.a(-1))
a(0)=a(0).neqv.(.not.a(1))
a(-3)=a(-1).neqv.(.not.a(1))
print *,a(-3),a(-2),a(-1),a(0),a(1)
end program probe
