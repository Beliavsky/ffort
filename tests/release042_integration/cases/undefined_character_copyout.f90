program p
implicit none
character(2),allocatable::x(:)
call fill(2,x)
print *,x(2)
contains
subroutine fill(n,a)
integer,intent(in)::n
character(len=n),allocatable,intent(out)::a(:)
allocate(a(2))
a(1)='ok'
end subroutine
end program
