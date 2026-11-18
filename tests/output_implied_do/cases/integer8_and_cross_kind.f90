program main
implicit none
integer(8)::i
integer::j
print *, (i,i=9007199254740993_8,9007199254740997_8,2_8)
print *,i
print *, (j,j=1_8,3_8)
print *,j
end program
