program p
implicit none
character(2)::a(2)
character(4)::b(2)
print *,kind(max(a,b)),len(max(a,b))
end program
