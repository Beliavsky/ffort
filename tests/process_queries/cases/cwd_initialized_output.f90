program p
implicit none
call q()
contains
subroutine q()
character(256)::v='old'
call getcwd(v)
end subroutine
end program
