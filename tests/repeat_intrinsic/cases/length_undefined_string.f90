program p
implicit none
character(7)::s
integer::n
n=3
print *,len(repeat(s,n)),len(repeat(s,0)),kind(repeat(s,n))
end program
