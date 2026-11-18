program p
implicit none
integer::a(1)
call sub(a)
contains
subroutine sub(x)
integer,intent(in)::x(2147483647:)
if(lbound(x,1)/=(2147483647).or.ubound(x,1)/=(2147483647))error stop 1
if(any(lbound(x,kind=8)/=[2147483647]).or.any(ubound(x,kind=8)/=[2147483647]))error stop 2
end subroutine
end program
