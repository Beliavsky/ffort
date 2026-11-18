program p
implicit none
character(len=*),parameter::fmt='(*(g0,1x))'
real(kind=8)::a(2)
a=[0.0_8,2.0_8]
print '(a)','before'
print fmt,asin(a)
end program
