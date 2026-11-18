program elemental_test
implicit none
integer::aa(2,2,2)
aa=2
print *,compute(aa)
contains
elemental integer function compute(xx) result(rr)
integer,intent(in)::xx
rr=xx*xx+1
end function compute

end program
