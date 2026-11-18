program p
implicit none
integer::a(0),b(2,0),c(1,0,2)
print *,size(maskr(a,8)),kind(maskr(a,8))
print *,size(maskr(b,8)),size(maskr(c,8))
end program
