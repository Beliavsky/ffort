program p
implicit none
character(:),allocatable::fmt,s
integer::i
fmt='(*(i0,:,":"))'
s=repeat(' ',11)
write(s,fmt)(i,i=1,4)
print '(a,i0,a,i0,a)', '['//s//']/',s%len,'/',fmt%len,'.'
end program
