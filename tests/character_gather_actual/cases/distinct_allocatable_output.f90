module m
implicit none
contains
subroutine copy(v,y)
character(*),intent(in)::v(:)
character(*),allocatable,intent(out)::y(:)
allocate(y(size(v)))
y=v
end subroutine
end module
program main
use m
implicit none
character(2)::x(-1:1)=['ab','cd','ef']
integer::i(4)=[1,-1,1,0]
character(2),allocatable::y(:)
call copy(x(i),y)
print "(a)",y
end program
