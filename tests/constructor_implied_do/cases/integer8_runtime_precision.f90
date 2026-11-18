program main
implicit none
integer(8)::i,a(3),lo,hi,st
i=99_8
lo=9007199254740993_8
hi=9007199254740997_8
st=2_8
a=[(i,i=lo,hi,st)]
print *,a,i,kind(a)
end program
