program p
implicit none
integer(8),parameter::k=8,n(3)=[0,1,64]
print *,maskl(n,kind=k)
print *,maskr(n,kind=k)
print *,shiftr(-1_8,n)
end program
