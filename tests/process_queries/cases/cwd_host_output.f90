program p
implicit none
character(256)::v
call q()
contains
subroutine q()
call getcwd(v)
end subroutine
end program
