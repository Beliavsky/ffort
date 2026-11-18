program p
implicit none
character(32)::fmt
integer::i,j
fmt='(*(i0,:,","))'
write(unit=*,fmt=fmt) ((10*i+j,j=1,i),i=1,3)
print '(2(i0,1x))',i,j
end program
