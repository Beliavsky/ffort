program p
implicit none
integer(8),parameter::k=4_4,n(3)=[0_4,1_4,32_4]
print *,maskl(n,kind=k)
print *,maskr(n,kind=k)
print *,shiftr(-1_4,n)
end program
