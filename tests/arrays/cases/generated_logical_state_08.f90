program probe
implicit none
logical :: a(0:4)
a(0)=.false.
a(1)=.true.
a(2)=.true.
a(3)=.false.
a(4)=.false.
a(3)=a(4).neqv.(.not.a(4))
a(1)=a(4).neqv.(.not.a(0))
a(3)=a(3).neqv.(.not.a(0))
a(2)=a(2).neqv.(.not.a(0))
a(2)=a(1).neqv.(.not.a(4))
a(2)=a(3).neqv.(.not.a(2))
a(3)=a(3).neqv.(.not.a(0))
a(3)=a(0).neqv.(.not.a(4))
a(1)=a(1).neqv.(.not.a(1))
a(3)=a(4).neqv.(.not.a(4))
a(0)=a(4).neqv.(.not.a(4))
a(4)=a(2).neqv.(.not.a(2))
print *,a(0),a(1),a(2),a(3),a(4)
end program probe
