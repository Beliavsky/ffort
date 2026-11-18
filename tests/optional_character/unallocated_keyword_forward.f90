program main
implicit none
character(:),allocatable::a(:)
call outer(x=a)
allocate(character(2)::a(0))
call ordinary(x=a,expected=.true.)
print *, 'PASS' 
contains
subroutine outer(x)
character(:),allocatable,optional,intent(in)::x(:)
if(.not.present(x)) error stop 1
call ordinary(expected=.false.,x=x)
end subroutine
subroutine ordinary(x,expected)
character(*),optional,intent(in)::x(:)
logical,intent(in)::expected
if(present(x).neqv.expected) error stop 2
end subroutine
end program
