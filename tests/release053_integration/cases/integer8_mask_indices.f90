program p
implicit none
integer(8) :: a(-1:2),b(3),ix(3)
a=[10_8,20_8,30_8,40_8]
ix=[int(iand(maskr(2,kind=8),1_8),8),-1_8,shiftr(maskr(2,kind=8),1)]
b=a(ix)
write(*,'(3i4)')b
end program
