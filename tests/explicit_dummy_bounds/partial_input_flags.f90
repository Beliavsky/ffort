program main
implicit none
integer::a(5)
a(1)=17
call work(a,3)
contains
subroutine work(x,n)
integer,intent(in)::n
integer,intent(in)::x(n)
print *,size(x),x(1)
end subroutine
end program
