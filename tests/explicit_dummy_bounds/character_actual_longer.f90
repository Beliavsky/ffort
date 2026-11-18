program main
implicit none
character(3)::a(4)
a='abc'
call forward(a,2)
contains
subroutine forward(x,n)
integer,intent(in)::n
character(*),intent(inout)::x(:)
call work(x,n)
end subroutine
subroutine work(x,n)
integer,intent(in)::n
character(2),intent(in)::x(n)
print *,len(x),size(x)
end subroutine
end program
