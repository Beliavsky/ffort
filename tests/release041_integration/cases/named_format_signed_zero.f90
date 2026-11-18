program p
implicit none
character(len=*),parameter::fmt='(f8.3,1x,f8.3)'
real(kind=8)::x
x=-0.0_8
print fmt,atan(x),atan2(x,1.0_8)
end program
