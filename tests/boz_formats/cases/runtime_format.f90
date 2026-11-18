program p
implicit none
character(20)::fmt
fmt='(a,o0.12,a)'
write(*,fmt=fmt)'[',-1,']'
end program
