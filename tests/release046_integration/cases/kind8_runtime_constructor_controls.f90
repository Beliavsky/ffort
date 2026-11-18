program p
implicit none
integer(8)::i,lo,hi,a(3)
i=77
lo=9007199254740993_8
hi=9007199254740997_8
a=[(i,i=lo,hi,2_8)]
print '(5i22)',a,lbound(a,kind=8),ubound(a,kind=8)
print '(i0)',i
end program
