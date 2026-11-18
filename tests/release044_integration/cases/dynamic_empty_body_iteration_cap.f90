program p
implicit none
integer::i,a(0)
character(24)::fmt
fmt='(*(i0))'
write(*,'(a)',advance='no')'kept:'
print fmt,(a,i=1,65537)
end program
