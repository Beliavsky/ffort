program p
implicit none
integer(8),parameter::k=4,n(3)=[0,1,32]
print *,maskl(n,kind=k)
print *,maskr(n,kind=k)
print *,shiftr(-1,n)
end program
