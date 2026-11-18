program main
implicit none
call emit(9)
contains
subroutine emit(n)
integer,intent(in)::n
write(*,'(a,1x,i0)')'seen',n
end subroutine
end program
