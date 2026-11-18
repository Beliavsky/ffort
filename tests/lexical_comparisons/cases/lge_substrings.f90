program p
implicit none
character(4)::a
a='abcd'
print *,lge(a(1:2),'ab '),lge('abc'(2:3),'bd')
end program
