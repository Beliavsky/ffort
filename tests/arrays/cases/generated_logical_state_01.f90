program probe
implicit none
logical :: a(-2:2)
a(-2)=.false.
a(-1)=.true.
a(0)=.true.
a(1)=.true.
a(2)=.true.
a(0)=a(2).neqv.(.not.a(-2))
a(2)=a(-2).neqv.(.not.a(1))
a(-2)=a(-2).neqv.(.not.a(-2))
a(0)=a(0).neqv.(.not.a(1))
a(2)=a(-2).neqv.(.not.a(-2))
a(2)=a(1).neqv.(.not.a(1))
a(0)=a(1).neqv.(.not.a(-2))
a(-1)=a(2).neqv.(.not.a(1))
a(0)=a(2).neqv.(.not.a(-2))
a(1)=a(2).neqv.(.not.a(2))
a(1)=a(-2).neqv.(.not.a(0))
a(0)=a(0).neqv.(.not.a(2))
print *,a(-2),a(-1),a(0),a(1),a(2)
end program probe
