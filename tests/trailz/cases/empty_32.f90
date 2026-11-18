program p
implicit none
integer(4)::a(0),b(2,0),c(1,0,2)
print *,size(trailz(a)),kind(trailz(a)),size(trailz(b)),kind(trailz(c))
end program p
