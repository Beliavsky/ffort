module optional_undefined
implicit none
contains
subroutine inspect(a,b)
integer,optional,intent(in) :: a
integer,optional,intent(out) :: b
print *,present(a),present(b)
if(present(b)) b=31
end subroutine
end module
program undefined_presence
use optional_undefined
implicit none
integer :: a,b
call inspect(a,b)
print *,b
call inspect()
end program
