program main
implicit none
character(:),allocatable::a(:)
call bad(a)
contains
subroutine bad(x)
character(*),allocatable,intent(out)::x(:)
end subroutine

end program
