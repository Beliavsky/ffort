program p
implicit none
integer::i
character(24)::fmt
fmt='(*(i0))'
write(*,'(a)',advance='no')'kept:'
print fmt,(i,i=1,1000)
end program
