program main
implicit none
integer::a(5)
a=99
call work(a,3)
print *,a
contains
subroutine work(x,n)
integer,intent(in)::n
integer,intent(out)::x(n)
integer::scratch(size(x))
scratch=12
x=scratch
end subroutine
end program
