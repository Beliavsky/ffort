program p
implicit none
integer::i,a(2)
character(24)::fmt
fmt='(*(i0,1x))'
a(1)=11
write(*,'(a)',advance='no')'kept:'
print fmt,(a(i),i=1,2)
end program
