program p
implicit none
integer(4),parameter::k=4_8,n(3)=[0_8,1_8,32_8]
print *,maskl(n,kind=k)
print *,maskr(n,kind=k)
print *,shiftr(-1_4,n)
end program
