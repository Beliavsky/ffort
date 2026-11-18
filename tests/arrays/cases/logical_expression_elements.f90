program probe
implicit none
logical :: a(2)
integer :: b(2)
a(1)=.true.
a(2)=.false.
b(1)=3
b(2)=5
print *,a(1).neqv.a(2),.not.a(1),b(1)<b(2),(a(1).and.b(2)==5)
end program probe
