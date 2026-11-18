program p
implicit none
character(20)::fmt
fmt='(a,t2,a)'
write(*,fmt)'abc','X'
fmt='(a,tr2,a)'
write(*,fmt)'abc','X'
end program
