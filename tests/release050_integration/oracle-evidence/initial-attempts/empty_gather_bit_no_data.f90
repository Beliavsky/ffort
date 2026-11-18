program p

implicit none
integer::a(2,3,1),g(2,0,1),n
character(5)::s(1)
g=shiftr(a(:,[integer::],:),n)
write(s(1),'(i0,1x,i0)')size(g),kind(maskl(0,kind=8))
print '(a)','['//s(1)//']' 
end program
