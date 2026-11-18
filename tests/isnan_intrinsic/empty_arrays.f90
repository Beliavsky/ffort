program p
implicit none
real::a(0),b(0,2),c(2,0,2)
print *,size(isnan(a)),size(isnan(b)),size(isnan(c)),any(isnan(a))
end program
