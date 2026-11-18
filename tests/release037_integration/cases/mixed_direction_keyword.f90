program main
implicit none
real(4)::x
real(8)::s
real(8)::a(2)
integer(8)::e(2)
x=1.0
s=tiny(0d0)*epsilon(0d0)
a=[1d0,-8d0]
e=[2_8,-2_8]
write(*,'("mixed:",4(1x,i0))')merge(1,0,nearest(s=s,x=x)>x),kind(nearest(s=s,x=x)), &
merge(1,0,nearest(x=x,s=-s)<x),kind(nearest(x=s,s=x))
write(*,'("keywords:",6(1x,i0))')int(set_exponent(i=e,x=a)*8d0),exponent(x=a), &
kind(fraction(x=a)),kind(iachar(kind=8,c='Q'))
end program
