program p
implicit none
print *,shiftr(maskl(2,kind=8),1),iand(maskr(3,kind=8),3_8)
end program
