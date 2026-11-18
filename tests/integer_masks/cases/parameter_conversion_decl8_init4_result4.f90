program p
implicit none
integer(8),parameter::k=4_4,n=2_4,sh=1_4
print *,kind(k),kind(n),kind(sh)
print *,maskl(n,kind=k),maskr(n,kind=k),shiftr(-1_4,sh)
print *,kind(maskl(n,kind=k)),kind(maskr(n,kind=k)),kind(shiftr(-1_4,sh))
end program
