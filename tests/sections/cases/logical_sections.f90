program probe
implicit none
logical :: a(1:4)
a(1)=.true.
a(2)=.false.
a(3)=.false.
a(4)=.true.
a(4:1:-1)=.not.a(:)
print *, a,a(1:3:2).eqv..true.
end program probe
