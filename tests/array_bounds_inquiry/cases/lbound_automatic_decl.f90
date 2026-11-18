program p
implicit none
real::x(-2:0,5:6)
call sub(x)
contains
subroutine sub(x)
real,intent(in)::x(-2:,5:)
integer::v(lbound(x,1,kind=8):lbound(x,2,kind=8))
if(size(v)/=8)error stop 1
end subroutine
end program
