program p
implicit none
character(len=*),parameter::fmt='(*(g0,1x))'
real(kind=8)::a(2),b(2)
a=[1.0_8,0.0_8]
b=[1.0_8,0.0_8]
print '(a)','before'
print fmt,atan(a,b)
end program
