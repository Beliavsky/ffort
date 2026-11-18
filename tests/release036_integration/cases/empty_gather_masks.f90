program main
implicit none
real(8)::a(2,3),z(0,3)
integer::rows(0)
logical::m(0,3)
a=1d0
z=dim(a(rows,:),epsilon(a))
m=z>tiny(z)
write(*,'("empty:",6(1x,i0))')shape(z),count(m),count(parity(m,dim=1)),size(parity(m,dim=2)),merge(1,0,parity(m))
write(*,'("models:",4(1x,i0))')kind(epsilon(z)),radix(z),kind(tiny(z)),kind(huge(z))
end program
