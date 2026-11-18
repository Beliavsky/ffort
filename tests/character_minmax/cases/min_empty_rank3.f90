program p
implicit none
character(2)::a(0,2,3)
character(4)::b(0,2,3)
print *,size(min(a,b)),len(min(a,b)),kind(min(a,b))
end program
