program p
implicit none
character(1)::c
call getcwd(c)
write(*,'(A)') '['//c//']'
end program
