program main
implicit none
integer::a(3,2)
a=1
call f(a,a)
contains
subroutine f(x,y)
integer,optional,intent(inout)::x(:,:),y(:,:)
x=2
y=3
end subroutine
end program
