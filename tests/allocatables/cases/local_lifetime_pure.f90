module m
contains
pure function fresh(n) result(ans)
integer,intent(in)::n
integer::ans
integer,allocatable::a(:)
if(allocated(a)) error stop 1
allocate(a(n))
a=4
ans=sum(a)
end function
end module
program main
use m
print *,fresh(3),fresh(2)
end program
