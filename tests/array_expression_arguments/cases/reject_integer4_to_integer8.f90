module m
implicit none
contains
integer(8) function total(a) result(r)
integer(8),intent(in)::a(:)
r=sum(a)
end function
end module
program p
use m
implicit none
integer(4),parameter::a(2)=[1,2]
print *,total(a+1)
end program
