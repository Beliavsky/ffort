program p
call check()
call check(procedure=5)
contains
subroutine check(procedure)
integer,intent(in),optional::procedure
if(present(procedure)) then
 if(procedure/=5) error stop 1
 print *, 'present'
else
 print *, 'absent'
end if
end subroutine
end program
