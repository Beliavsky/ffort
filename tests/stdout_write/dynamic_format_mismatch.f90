program main
implicit none
integer::a(2)
a=2
call emit(a)
contains
subroutine emit(x)
integer,intent(in)::x(:)
write(*,'(i0,a)')x
end subroutine
end program
