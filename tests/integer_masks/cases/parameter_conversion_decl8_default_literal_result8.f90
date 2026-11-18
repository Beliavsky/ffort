program p
implicit none
integer(8),parameter::k=8,n=2,sh=1
print *,kind(k),kind(n),kind(sh)
print *,maskl(n,kind=k),maskr(n,kind=k),shiftr(-1_8,sh)
print *,kind(maskl(n,kind=k)),kind(maskr(n,kind=k)),kind(shiftr(-1_8,sh))
end program
