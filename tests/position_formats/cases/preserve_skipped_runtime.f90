program p
implicit none
character(80)::fmt
fmt='(a,t1,a,2x,a)'
write(*,fmt) 'abcdef','Z','Q'
end program
