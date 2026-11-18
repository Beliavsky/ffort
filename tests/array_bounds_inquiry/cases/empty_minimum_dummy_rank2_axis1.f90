program p
implicit none
integer::a(0,2)
call sub(a)
contains
subroutine sub(x)
integer,intent(in)::x(-2147483647-1:,3:)
if(any(lbound(x)/=[1,3]))error stop 1
if(any(ubound(x)/=[0,4]))error stop 2
if(any(lbound(x,kind=8)/=[1,3]))error stop 3
if(any(ubound(x,kind=8)/=[0,4]))error stop 4
if(lbound(x,1)/=1.or.ubound(x,1)/=0)error stop 5
end subroutine
end program
