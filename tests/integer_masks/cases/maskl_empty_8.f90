program p
implicit none
integer::a(0),b(2,0),c(1,0,2)
print *,size(maskl(a,8)),kind(maskl(a,8))
print *,size(maskl(b,8)),size(maskl(c,8))
end program
