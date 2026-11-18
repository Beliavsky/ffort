program p
call check(procedure=1)
contains
subroutine check(procedure)
character(*),intent(in)::procedure
end subroutine
end program
