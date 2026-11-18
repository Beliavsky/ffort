program p
implicit none
character(8)::fmt
fmt="(i0"
write(*,"(a)",advance="no")"OK"
print fmt,1
end program
