program p
implicit none
character(80)::fmt
fmt='(*(a,tl1,a))'
write(*,fmt) 'abc','X','def','Y'
end program
