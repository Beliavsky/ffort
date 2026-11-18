program p
implicit none
integer(4),parameter::k=8_8,n=2_8,sh=1_8
print *,kind(k),kind(n),kind(sh)
print *,maskl(n,kind=k),maskr(n,kind=k),shiftr(-1_8,sh)
print *,kind(maskl(n,kind=k)),kind(maskr(n,kind=k)),kind(shiftr(-1_8,sh))
end program
