program integrated_wide
implicit none
integer(kind=8),parameter :: aa(2)=[9007199254740993_8,9223372036854775807_8]
print '(i0)', aa(1)
print '(i0)', aa(2)
end program
