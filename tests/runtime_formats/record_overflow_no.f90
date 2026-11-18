program p
implicit none

write(*,"(a)",advance="no")"X"
write(*,"(a)",advance="no")repeat("y",65536)
end program
