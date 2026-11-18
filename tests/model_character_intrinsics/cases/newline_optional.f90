program p
implicit none
call test()
contains
subroutine test(c)
character(*),intent(in),optional::c
print *,iachar(new_line(c))
end subroutine
end program
