program p
call check('one')
call check(procedure='two')
contains
subroutine check(procedure)
character(*),intent(in)::procedure
if(procedure/='one'.and.procedure/='two') error stop 1
print *,trim(procedure)
end subroutine
end program
