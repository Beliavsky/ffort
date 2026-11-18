program p
implicit none
call sub(2)
contains
subroutine sub(d)
integer,optional,intent(in)::d
real::x(-2:0,5:6)
if(lbound(x,(d))/=5)error stop 1
end subroutine
end program
