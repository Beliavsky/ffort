program p
implicit none
character(2)::a(2)
character(4)::b(2)
print *,kind(min(a,b)),len(min(a,b))
end program
