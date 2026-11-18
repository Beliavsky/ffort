program p
implicit none
character(2)::a(2,1,2)
character(3)::b(2,1,2)
logical::x(2,1,2)
a='ab'
b='abc'
x=lge(a,b)
print *,x
end program
