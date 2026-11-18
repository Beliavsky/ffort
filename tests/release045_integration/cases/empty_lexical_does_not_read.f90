program p
implicit none
character(2)::a(0)
logical::m(0)
real(8)::z(0)
m=llt(a,'x')
print '(i0,1x,l1,1x,f3.1)',size(m),all(m),norm2(z)
end program
