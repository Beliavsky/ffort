program p
implicit none
character(20)::fmt
fmt='(a,"   ")'
write(*,fmt,advance='no')'A'
print '(a)','B'
end program
