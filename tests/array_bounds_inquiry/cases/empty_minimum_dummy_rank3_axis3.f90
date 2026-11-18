program p
implicit none
integer::a(2,2,0)
call sub(a)
contains
subroutine sub(x)
integer,intent(in)::x(3:,3:,-2147483647-1:)
if(any(lbound(x)/=[3,3,1]))error stop 1
if(any(ubound(x)/=[4,4,0]))error stop 2
if(any(lbound(x,kind=8)/=[3,3,1]))error stop 3
if(any(ubound(x,kind=8)/=[4,4,0]))error stop 4
if(lbound(x,3)/=1.or.ubound(x,3)/=0)error stop 5
end subroutine
end program
