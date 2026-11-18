program p
implicit none
character(80)::fmt
fmt='(a,t2,a,:,tr5,"tail")'
write(*,fmt) 'abc','X'
end program
