! GNU-valid Fortran: absence forwarded to an intrinsic optional argument.
! This interpreter release supports absence forwarding to user procedures only.
module intrinsic_absence
implicit none
contains
subroutine probe(precision_arg)
integer,optional,intent(in) :: precision_arg
integer :: values(2,2)
values(1,1)=1
values(2,1)=2
values(1,2)=3
values(2,2)=4
print *,selected_real_kind(p=precision_arg)
end subroutine
end module
program intrinsic_absence_test
use intrinsic_absence
implicit none
call probe()
end program
