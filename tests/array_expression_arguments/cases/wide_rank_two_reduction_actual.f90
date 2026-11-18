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
integer(8),parameter::a(2,2)=9007199254740993_8
print *,total(sum(a,dim=1))
end program
