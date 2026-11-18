program main
implicit none
integer::a(500001)
a=1
call work(a,500001)
contains
subroutine work(x,n)
integer,intent(in)::n
integer,intent(in)::x(n)
integer::scratch(n)
scratch=1
print *,size(x)
end subroutine
end program
