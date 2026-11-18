module m
implicit none
contains
subroutine report(char)
integer,allocatable,optional,intent(in)::char(:)
integer::work(size(char))
work=7
write(*,'(2(i0))')work
end subroutine
end module
program main
end program
