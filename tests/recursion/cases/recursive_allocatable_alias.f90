program p
implicit none
integer,allocatable::x(:),y(:)
x=[1,2,3]
y=[4,5,6]
call bad(1,x,y)
contains
recursive subroutine bad(n,a,b)
integer,intent(in)::n
integer,allocatable,intent(inout)::a(:),b(:)
if(n>0) then
call bad(n-1,a,a)
else
a=a+1
b=b+2
end if
end subroutine
end program
