program p
implicit none
integer(8)::x
character(:),allocatable::s,c(:)
x=9007199254740993_8
s='wide='
c=[s]
print '(a,z16.16)',c,ieor(x,2_8)
end program
