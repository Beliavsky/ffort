program p
implicit none
character(20)::fmt
fmt='(i1,4x)'
print fmt,1
write(*,fmt)2
end program
