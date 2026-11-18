program p
implicit none
character(2)::a(0,2,3)
character(4)::b(0,2,3)
print *,size(max(a,b)),len(max(a,b)),kind(max(a,b))
end program
