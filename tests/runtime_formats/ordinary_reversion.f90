program p
implicit none
character(12)::fmt
fmt='(i1,2x)'
write(*,fmt,advance='no')[1,2]
print '(a)','X'
end program
