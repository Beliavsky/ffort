program p
implicit none
contains
simple subroutine q()
character(256)::v
call getcwd(v)
end subroutine
end program
