program p
implicit none
call q()
contains
subroutine q()
character(256),save::v='old'
call getcwd(v)
end subroutine
end program
