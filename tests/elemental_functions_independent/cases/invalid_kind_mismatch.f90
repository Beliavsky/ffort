program elemental_test
implicit none
real::aa(2)
aa=2.0
print *,compute(aa)
contains
elemental real(8) function compute(xx) result(rr)
real(8),intent(in)::xx
rr=xx
end function compute

end program
