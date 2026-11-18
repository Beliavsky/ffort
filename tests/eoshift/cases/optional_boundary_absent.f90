program p
implicit none
call f()
contains
subroutine f(b)
integer,intent(in),optional::b
write(*,'(*(i0,1x))')eoshift([1,2,3],1,b)
end subroutine
end program
