program p
implicit none
character(256)::v
call q(v)
contains
subroutine q(v)
character(256),intent(out),optional::v
call getcwd(v)
end subroutine
end program
