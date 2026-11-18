program probe
implicit none
logical :: a(2:6)
a(2)=.true.
a(3)=.true.
a(4)=.false.
a(5)=.true.
a(6)=.true.
a(4)=a(3).neqv.(.not.a(5))
a(2)=a(4).neqv.(.not.a(5))
a(3)=a(3).neqv.(.not.a(5))
a(5)=a(6).neqv.(.not.a(2))
a(2)=a(5).neqv.(.not.a(3))
a(5)=a(3).neqv.(.not.a(5))
a(2)=a(6).neqv.(.not.a(2))
a(6)=a(2).neqv.(.not.a(3))
a(2)=a(6).neqv.(.not.a(4))
a(5)=a(5).neqv.(.not.a(5))
a(2)=a(4).neqv.(.not.a(4))
a(3)=a(5).neqv.(.not.a(5))
print *,a(2),a(3),a(4),a(5),a(6)
end program probe
