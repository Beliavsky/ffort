program p
implicit none
character(2)::a
integer::u
u=27
read(u,'(a)')a
print '(a)','SAFE'
print '(l1)',llt(a,'z')
end program
