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
integer(8),parameter::a(2)=[9007199254740993_8,2_8]
integer(8),parameter::b(2)=a+1_8
print *,total(b(:)),total(a+1_8)
end program
