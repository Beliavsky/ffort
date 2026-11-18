program main
implicit none
integer::a(3),b(3)
a=1
b=2
call work(a,b)
contains
subroutine work(x,y)
integer,intent(in)::x(:)
integer,intent(in)::y(x(1))
return
end subroutine
end program
