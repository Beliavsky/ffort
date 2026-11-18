program p
implicit none
character(3),allocatable::x(:)

call fill(3,x,x)
contains
subroutine fill(n,a,b)
integer,intent(in)::n
character(len=n),allocatable,intent(inout)::a(:),b(:)
print '(a)','body leaked'
end subroutine
end program
