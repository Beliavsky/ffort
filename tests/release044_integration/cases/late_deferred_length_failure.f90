program p
implicit none
character(:),allocatable::s
character(24)::fmt
integer::i
fmt='(*(i0,1x))'
write(*,'(a)',advance='no')'kept:'
print fmt,(i,s%len,i=1,2)
end program
