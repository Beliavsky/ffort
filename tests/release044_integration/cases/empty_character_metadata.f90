program p
implicit none
character(7)::empty(0)
character(24)::fmt
integer::i
fmt='(*(i0,1x))'
print fmt,(empty%len,i=3,1,-1),size(empty),i
end program
