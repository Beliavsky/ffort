program main
implicit none
integer(8)::i,a(3)
i=99_8
a=[(i,i=9007199254740993_8,9007199254740997_8,2_8)]
print *,a,i,kind(a)
end program
