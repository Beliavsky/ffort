program p
implicit none
character(3)::words(2)
character(:),allocatable::fmt
integer::i
words=['a  ',' b ']
fmt='(*(a,"/",i0,:,":"))'
print fmt,(words(i),words%len,i=2,1,-1)
end program
