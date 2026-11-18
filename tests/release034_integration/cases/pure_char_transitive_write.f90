module m
implicit none
contains
subroutine emit(char)
integer,allocatable,intent(in)::char(:)
integer::work(size(char))
work=1
write(*,'(2(i0))')work
end subroutine
pure subroutine report(char)
integer,allocatable,intent(in)::char(:)
call emit(char)
end subroutine
end module
program main
end program
