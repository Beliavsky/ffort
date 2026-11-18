program p
implicit none
character(20)::fmt
fmt='(*(i1,:,2x))'
write(*,fmt,advance='no')[1,2,3]
print '(a)','X'
end program
