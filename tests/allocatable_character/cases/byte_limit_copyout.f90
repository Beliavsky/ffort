program main
implicit none
character(65536),allocatable::a(:),b(:)
allocate(a(200))
call make(b)
contains
subroutine make(x)
character(*),allocatable,intent(out)::x(:)
allocate(x(100))
end subroutine

end program
