program p
implicit none
character(:),allocatable::s
s='abc'
call clear_value(s)
if(len(s)/=3.or..not.allocated(s)) error stop 1
s(:)='x'
if(s/='x  ') error stop 2
contains
subroutine clear_value(x)
character(*),intent(out)::x
if(len(x)/=3) error stop 3
end subroutine
end program
