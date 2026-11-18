program p
implicit none
character(256)::c
call getcwd(c)
write(*,'(A)') trim(c)
end program
