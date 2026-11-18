module m
implicit none
contains
integer(4) function total(a) result(r)
integer(4),intent(in)::a(:)
r=sum(a)
end function
end module
program p
use m
implicit none
integer(8),parameter::a(2)=[1_8,2_8]
print *,total(a+1_8)
end program
