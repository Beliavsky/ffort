program p
implicit none
character(80)::fmt
fmt='(a,t5,"",tl3,a)'
write(*,fmt) 'abc','X'
end program
