module m
implicit none
contains
pure function padded(a) result(b)
integer,intent(in)::a(:)
integer::b(3)
b=pack(a,a>0,[-1,-1,-1])
end function
pure integer function total(a)
integer,intent(in)::a(:)
total=sum(a)
end function
end module
program main
use m
implicit none
print *,padded([-2,5,6]),total(pack([-2,5,6],[-2,5,6]>0))
end program
