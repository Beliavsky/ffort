program main
call s()
contains
subroutine s(x)
real,optional,intent(in)::x(:,:)
if(kind(ubound(x,kind=8))/=8) error stop 1
end subroutine
end program
