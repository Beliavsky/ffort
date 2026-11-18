program p
implicit none
integer::a(0),b(2,0),c(1,0,2)
print *,size(maskl(a,4)),kind(maskl(a,4))
print *,size(maskl(b,4)),size(maskl(c,4))
end program
