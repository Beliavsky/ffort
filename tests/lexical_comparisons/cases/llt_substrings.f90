program p
implicit none
character(4)::a
a='abcd'
print *,llt(a(1:2),'ab '),llt('abc'(2:3),'bd')
end program
