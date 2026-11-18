program p
implicit none
call sub(2)
contains
subroutine sub(d)
integer,optional,intent(in)::d
real::x(-2:0,5:6)
if(ubound(x,(d))/=6)error stop 1
end subroutine
end program
