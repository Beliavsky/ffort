program p
implicit none
character(24)::fmt
integer::i,undefined
fmt='(i0'
write(*,'(a)',advance='no')'kept:'
print fmt,(i,i=undefined,1)
end program
