module combined_hyperbolic_arrays
implicit none
integer,parameter :: dp=selected_real_kind(15,307)
contains
elemental function sech(xx) result(yy)
! hyperbolic secant
real(kind=dp), intent(in) :: xx
real(kind=dp)             :: yy
yy = 1/cosh(xx)
end function sech
pure function samples(n) result(y)
integer,intent(in)::n
real(dp)::y(-2:n-3),scratch(n)
integer::j
do j=1,n
scratch(j)=dble(j-2)/4.0_dp
end do
y=scratch
end function
pure function grid(n,m) result(y)
integer,intent(in)::n,m
real(dp)::y(n,m)
integer::i,j
do j=1,m
do i=1,n
y(i,j)=dble(i+j-3)/4.0_dp
end do
end do
end function
end module
program hyperbolic_array_results
use combined_hyperbolic_arrays
implicit none
real(dp)::a(3),b(2,2),empty(0)
a=sinh(samples(3))+tanh(samples(3))
b=cosh(grid(2,2))
print *,a,b
print *,sech(samples(3)),sum(sech(samples(3)))
print *,sum(sinh(samples(4))),sum(cosh(samples(4))),sum(tanh(samples(4)))
print *,sum(sech(grid(2,2)),dim=1),sum(tanh(grid(2,2)),dim=2)
empty=sech(samples(0))+sinh(samples(0))+tanh(samples(0))
print *,size(empty),size(cosh(samples(0))),sum(cosh(samples(0)))
print *,sum(sech(samples(0))),sum(sinh(samples(0))),sum(tanh(samples(0)))
print *,size(cosh(grid(0,2)),dim=1),size(cosh(grid(0,2)),dim=2)
print *,sum(sinh(grid(0,2))),sum(cosh(grid(0,2))),sum(tanh(grid(0,2)))
end program
