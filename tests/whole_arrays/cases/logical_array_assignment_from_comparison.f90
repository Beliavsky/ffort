program probe
implicit none
integer :: a(3)
logical :: b(3)
a(1)=-1
a(2)=0
a(3)=1
b=.not.(a<0).and.(a/=0)
print *, b
end program probe
