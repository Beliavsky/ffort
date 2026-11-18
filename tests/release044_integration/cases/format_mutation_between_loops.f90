program p
implicit none
character(32)::fmt
integer::i
fmt='(*(i0,1x))'
write(*,fmt,advance='no')(i,i=1,2)
fmt='(*(i3.3,1x))'
write(*,fmt,advance='no')(i,i=3,4)
print '(a)','end'
end program
