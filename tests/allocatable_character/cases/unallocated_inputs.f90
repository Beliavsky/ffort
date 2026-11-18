program main
implicit none
character(7),allocatable::a(:)
character(:),allocatable::b(:)
call fixed_input(a)
call deferred_input(b)
contains
subroutine fixed_input(x)
character(*),allocatable,intent(in)::x(:)
if(allocated(x).or.len(x)/=7) error stop 1
end subroutine
subroutine deferred_input(x)
character(:),allocatable,intent(in)::x(:)
if(allocated(x)) error stop 2
end subroutine

end program
