module m
contains
subroutine emit(n)
integer,intent(in)::n
character(4)::s(2)
write(s(2),'(z4.4)')maskr(n)
print '(a)',s(2)
end subroutine
end module
program p
use m
implicit none
select case(iand(7,maskr(2)))
case(3);call emit(4)
case default;error stop 'wrong branch'
end select
end program
