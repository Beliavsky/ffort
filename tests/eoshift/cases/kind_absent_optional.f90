program p
implicit none
call f()
contains
subroutine f(a,s,b)
real(8),intent(in),optional::a(:),b
integer,intent(in),optional::s
write(*,'(i0)')kind(eoshift(a,s,b))
end subroutine
end program
