program p
implicit none
character(4)::a
a='abcd'
print *,lgt(a(1:2),'ab '),lgt('abc'(2:3),'bd')
end program
