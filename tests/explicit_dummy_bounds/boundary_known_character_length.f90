program main
implicit none
character(3)::a(4)
a='abc'
call work(a,2)
contains
subroutine work(x,n)
integer,intent(in)::n
character(2),intent(in)::x(n)
return
end subroutine
end program
