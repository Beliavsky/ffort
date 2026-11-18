program main
use original_utilities
implicit none
real(dp)::x(0),a(0,3)
logical::v(0),m(2,0),b(1,0,3)
x=ran_uni_vec(0)
x=runif_vec(0,2d0)
a=random_matrix(0,3)
v=random_logical_vec(0,2d0)
m=random_logical_matrix(2,0,0d0)
b=random_logical_3d(1,0,3,2d0)
write(*,'("empty_rng:",10(1x,i0))')size(x),shape(a),size(v),shape(m),shape(b),count(isnan(a))
end program
