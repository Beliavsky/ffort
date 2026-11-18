program p
call take('-')
contains
subroutine take(c)
character(*),intent(in)::c
if(c/='-') error stop 1
print *, 'input'
end subroutine
end program
