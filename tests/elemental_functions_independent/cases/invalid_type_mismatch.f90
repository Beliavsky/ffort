program elemental_test
implicit none
real::aa(2)
aa=2.0
print *,compute(aa)
contains
elemental integer function compute(xx) result(rr)
integer,intent(in)::xx
rr=xx*xx+1
end function compute

end program
