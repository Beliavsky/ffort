program p
implicit none
real(8),parameter::x=fraction(-10d0),y=set_exponent(10d0,3_8)
integer,parameter::e=exponent(10d0)
integer(8),parameter::c=iachar('Z',4+4)
print *,x,y,e,c,kind(x),kind(e),kind(c)
end program
