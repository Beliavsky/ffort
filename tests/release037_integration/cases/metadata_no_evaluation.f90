program main
implicit none
real(8),allocatable::a(:,:)
real(8)::s
integer::idx(2)
s=0d0
write(*,'("meta:",7(1x,i0))')kind(fraction(a(idx,:))),kind(exponent(a)), &
kind(set_exponent(a,huge(0_8))),kind(spacing(a)),kind(nearest(a,s)),kind(isnan(a)),kind(iachar('A',8))
write(*,'("status:",1x,i0)')merge(1,0,allocated(a))
end program
