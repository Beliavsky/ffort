module m

contains
pure subroutine make(a)
integer,allocatable,intent(out)::a(:)
a=[2,3]
end subroutine
pure function total() result(n)
integer::n
integer,allocatable::a(:)
call make(a)
n=sum(a)
end function
end module
program main
use m

print *,total(),total()
end program
