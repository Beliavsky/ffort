program main
use original_utilities
implicit none
real(dp)::x(9),original(9),empty(0),one(1),u
integer::order(9),eo(0),oo(1),i,matches,signs
u=tiny(0d0)*epsilon(0d0)
original=[3d0,-0d0,2d0,-u,-4d0,0d0,u,3d0,1d0]
x=set_exponent(fraction(original),exponent(original))
call quick_sort(x,order)
call quick_sort(empty,eo)
one=-0d0
call quick_sort(one,oo)
matches=0
signs=0
do i=1,size(x)
if(x(i)==original(order(i)))matches=matches+1
if(sign(1d0,x(i))==sign(1d0,original(order(i))))signs=signs+1
end do
write(*,'("sort:",5(1x,i0))')count(x(2:)>=x(:8)),matches,count(isnan(x)),sum(order),signs
write(*,'("edges:",6(1x,i0))')merge(1,0,x(1)==-4d0),merge(1,0,x(2)==-u), &
merge(1,0,x(5)==u),size(eo),oo,int(sign(1d0,one))
end program
