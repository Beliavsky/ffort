program p
implicit none
real(8)::x(3),a(3),b(3)
character(6)::label
character(24)::fmt
integer::i
x=[-1d0,0d0,1d0]
a=acosd(x)
b=asind(x)
fmt='(*(f6.1))'
print fmt,(a(i),b(i),i=1,3)
print '(i0)',label%len
end program
