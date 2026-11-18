program main
implicit none
integer::a(3)
a=1
call work(a,3)
contains
subroutine work(x,n)
integer,intent(in)::n
integer,optional,intent(in)::x(n)
return
end subroutine
end program
