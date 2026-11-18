program p
implicit none
character(8)::fmt
fmt="(i3.3)"
print fmt,7
fmt="(i0)"
write(*,fmt)8
end program
