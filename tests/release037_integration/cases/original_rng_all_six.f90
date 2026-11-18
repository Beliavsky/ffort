program main
use original_utilities
implicit none
real(dp)::x(7),y(4),z(4),m(2,3)
logical::v(5),b(2,3),c(2,1,3)
x=ran_uni_vec(7)
y=runif_vec(4)
z=runif_vec(4,2d0)
m=random_matrix(2,3)
v=random_logical_vec(5,0d0)
b=random_logical_matrix(2,3,2d0)
c=random_logical_3d(2,1,3,0d0)
write(*,'("ranges:",5(1x,i0))')count(x>=0d0.and.x<1d0),count(y>=0d0.and.y<1d0), &
count(z>=1.5d0.and.z<=2.5d0),count(m>=0d0.and.m<1d0),count(isnan(m))
write(*,'("logical:",6(1x,i0))')count(v),count(b),count(c(:,:,1))+count(c(:,:,2))+count(c(:,:,3)),size(c,1),size(c,2),size(c,3)
write(*,'("models:",4(1x,i0))')count(set_exponent(fraction(x),exponent(x))==x), &
count(spacing(m)>0d0),count(nearest(m,1d0)>m),kind(m)
end program
