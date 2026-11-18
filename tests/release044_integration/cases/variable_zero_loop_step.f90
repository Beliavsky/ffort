program p
implicit none
integer::i,step
character(24)::fmt
fmt='(*(i0))'
step=0
write(*,'(a)',advance='no')'kept:'
print fmt,(i,i=1,2,step)
end program
