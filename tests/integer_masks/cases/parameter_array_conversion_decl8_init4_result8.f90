program p
implicit none
integer(8),parameter::k=8_4,n(3)=[0_4,1_4,64_4]
print *,maskl(n,kind=k)
print *,maskr(n,kind=k)
print *,shiftr(-1_8,n)
end program
