program elemental_test
implicit none

print *,compute(0.5d0)
contains
pure elemental real(8) function compute(xx) result(rr)
real(8),intent(in)::xx
rr=xx+0.25d0
end function compute

end program
