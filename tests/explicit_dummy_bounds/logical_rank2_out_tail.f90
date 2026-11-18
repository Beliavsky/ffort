program main
implicit none
logical::a(2,3)
a=.true.
call work(a,2)
print *,a
contains
subroutine work(x,n)
integer,intent(in)::n
logical,intent(out)::x(1,n)
x=.false.
end subroutine
end program
