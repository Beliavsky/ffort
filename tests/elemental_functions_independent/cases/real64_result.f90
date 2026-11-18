program elemental_test
implicit none
real(8)::aa(3)
aa(1)=0.125d0
aa(2)=0.375d0
aa(3)=0.625d0
print *,compute(aa)
contains
elemental real(8) function compute(xx) result(rr)
real(8),intent(in)::xx
rr=xx+0.125d0
end function compute

end program
