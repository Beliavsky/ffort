program main
implicit none
integer::a(3)
a=1
call work(a,3)
contains
subroutine work(x,n)
integer,optional,intent(in)::n
integer,intent(in)::x(n)
return
end subroutine
end program
