module m
implicit none
integer::last=3,step=1
contains
impure elemental integer function change(x) result(r)
integer,intent(in)::x
last=0
step=0
r=x
end function
end module
program main
use m
implicit none
integer::i
print *, (change(i),i=1,last,step)
print *,i,last,step
end program
