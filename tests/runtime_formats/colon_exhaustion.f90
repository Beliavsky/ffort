program p
implicit none
character(20)::fmt
fmt='(i1,:,4x)'
write(*,fmt,advance='no')1
print '(a)','X'
end program
