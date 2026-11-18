program main
implicit none
call f()
contains
subroutine f(x)
integer,optional,intent(inout)::x(:,:)
if(size(x)>0) error stop 1
end subroutine
end program
