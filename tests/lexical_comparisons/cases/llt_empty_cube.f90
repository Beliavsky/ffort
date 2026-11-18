program p
implicit none
character(1)::a(0,2,3)
character(3)::b(0,2,3)
print *,size(llt(a,b)),kind(llt(a,b))
end program
