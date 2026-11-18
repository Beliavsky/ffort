program p
implicit none
real::x(-2:0,5:6)
call sub(x)
contains
subroutine sub(x)
real,intent(in)::x(-2:,5:)
integer::v(ubound(x,1,kind=8):ubound(x,2,kind=8))
if(size(v)/=7)error stop 1
end subroutine
end program
