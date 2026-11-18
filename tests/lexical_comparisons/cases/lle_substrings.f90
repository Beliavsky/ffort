program p
implicit none
character(4)::a
a='abcd'
print *,lle(a(1:2),'ab '),lle('abc'(2:3),'bd')
end program
