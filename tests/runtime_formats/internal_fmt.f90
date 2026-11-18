program p
implicit none
character(12)::fmt
character(5)::s
fmt="(i0)"
write(s,fmt=fmt)12
print "(a)","["//s//"]"
end program
