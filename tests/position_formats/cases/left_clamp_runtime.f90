program p
implicit none
character(80)::fmt
fmt='(a,tl65536,a)'
write(*,fmt) 'abc','Z'
end program
