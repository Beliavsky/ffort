program p
implicit none
character(24)::fmt
integer::i
fmt='("empty",:,i0)'
write(*,fmt,advance='no')(i,i=3,1)
print '(a,i0)',':i=',i
end program
