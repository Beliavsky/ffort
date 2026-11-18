program p
implicit none
integer::a(0),b(2,0),c(1,0,2)
print *,size(maskr(a,4)),kind(maskr(a,4))
print *,size(maskr(b,4)),size(maskr(c,4))
end program
