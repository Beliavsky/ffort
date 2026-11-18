program p
implicit none
character(len=*),parameter::fmt='(3(f10.6,1x))'
real(kind=8)::a(5)
a=[-1.0_8,3.0_8,0.0_8,4.0_8,1.0_8]
print fmt,atan(y=a(5:1:-2),x=1.0_8)
end program
