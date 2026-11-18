program probe
implicit none
logical :: a(3:7)
a(3)=.false.
a(4)=.true.
a(5)=.true.
a(6)=.true.
a(7)=.false.
a(7)=a(4).neqv.(.not.a(6))
a(3)=a(7).neqv.(.not.a(6))
a(7)=a(7).neqv.(.not.a(3))
a(4)=a(5).neqv.(.not.a(4))
a(5)=a(5).neqv.(.not.a(7))
a(5)=a(4).neqv.(.not.a(6))
a(3)=a(3).neqv.(.not.a(5))
a(5)=a(5).neqv.(.not.a(4))
a(5)=a(5).neqv.(.not.a(5))
a(6)=a(4).neqv.(.not.a(5))
a(3)=a(5).neqv.(.not.a(4))
a(7)=a(4).neqv.(.not.a(5))
print *,a(3),a(4),a(5),a(6),a(7)
end program probe
