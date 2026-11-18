program p
implicit none
character(24)::fmt
integer::i
fmt='(3(i2.2,1x))'
write(unit=fmt,fmt=fmt)(i,i=1,3)
print '(a)', '['//fmt//']'
if(i/=4)error stop 1
end program
