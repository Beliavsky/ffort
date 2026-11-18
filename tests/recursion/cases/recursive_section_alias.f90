program p
implicit none
integer::x(3),y(3)
x=1
y=2
call bad(1,x,y)
contains
recursive subroutine bad(n,a,b)
integer,intent(in)::n
integer,intent(inout)::a(:),b(:)
if(n>0) then
call bad(n-1,a(1:2),a(2:3))
else
a=a+1
b=b+2
end if
end subroutine
end program
