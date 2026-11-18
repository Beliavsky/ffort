program p
implicit none
character(12)::fmt
fmt='(a,2x)'
write(unit=*,fmt=fmt,advance='no')'A'
print '(a)','B'
end program
