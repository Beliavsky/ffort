program main
implicit none
real(8)::a(3,2),b(3,2),c(3,2)
integer::e(3,2)
character(1)::letters(3)
a=reshape([-8d0,0.5d0,3d0,16d0,-0.25d0,0d0],[3,2])
b=a([3,1,3],:)
e=exponent(b)
c=set_exponent(fraction(b),e)
letters=['A','z','0']
write(*,'("roundtrip:",4(1x,i0))')count(c==b),count(isnan(c)),count(spacing(c)>0d0),count(nearest(c,1d0)>c)
write(*,'("exponents:",6(1x,i0))')e
write(*,'("ascii:",5(1x,i0))')iachar(letters,kind=8),kind(iachar('A',8)),count(parity(b>0d0,dim=1))
end program
