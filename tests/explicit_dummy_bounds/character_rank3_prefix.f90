program main
implicit none
character(2)::a(1,2,3)
a='ab'
call work(a,2)
print *,a
contains
subroutine work(x,n)
integer,intent(in)::n
character(*),intent(out)::x(n,n,1)
x='q'
end subroutine
end program
