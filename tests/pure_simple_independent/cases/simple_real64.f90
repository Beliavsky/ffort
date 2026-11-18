program purity_test
implicit none

print *,compute(0.5d0)
contains
simple real(8) function compute(xx) result(rr)
real(8), intent(in) :: xx
rr=exp(xx*0.0d0)+sqrt(xx*xx)
end function compute

end program
