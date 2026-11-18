program main
implicit none
character(2)::a(2,3)
a='ab'
call work(a(2:1:-1,3:1:-1),2)
print *,a
contains
subroutine work(x,n)
integer,intent(in)::n
character(*),intent(out)::x(1,n)
x='q'
end subroutine
end program
