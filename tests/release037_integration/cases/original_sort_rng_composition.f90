program main
use original_utilities
implicit none
real(dp)::x(11),original(11)
integer::order(11),i,matches
original=runif_vec(11)
x=set_exponent(fraction(original),exponent(original))
call quick_sort(x,order)
matches=0
do i=1,size(x)
if(x(i)==original(order(i)))matches=matches+1
end do
write(*,'("sort_rng:",5(1x,i0))')count(x>=0d0.and.x<1d0),count(x(2:)>=x(:10)), &
matches,count(isnan(x)),count(nearest(x,1d0)>x)
end program
