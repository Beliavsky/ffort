program p
implicit none
character(2)::a(2,3)
character(3)::b(2,3)
logical::x(2,3)
a='a'
b='a '
x=llt(a,b)
print *,x,kind(x)
end program
