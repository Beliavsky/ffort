module m
implicit none
contains
subroutine lookup(iu,name)
integer,intent(in) :: iu
character(*),intent(out) :: name
inquire(unit=iu,name=name)
end subroutine
integer function measure(iu) result(n)
integer,intent(in) :: iu
character(18) :: name
call lookup(iu,name)
n=len_trim(name)
end function
end module
program p
use m
implicit none
integer :: iu,n
iu=17
! GNU_REGISTER_INPUT
write(*,'(a)',advance='no') 'KEEP'
n=measure(iu)
write(*,'(i0)') n
end program
