program p
implicit none
character(5)::fmt
fmt="(i0)"
write(fmt,fmt)42
print "(a)","["//fmt//"]"
end program
