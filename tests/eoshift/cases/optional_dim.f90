program p
implicit none
call f(1)
contains
subroutine f(d)
integer,intent(in),optional::d
write(*,*)eoshift([1,2],1,dim=d)
end subroutine
end program
