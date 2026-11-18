program elemental_test
implicit none
integer::aa(3)
aa=2
print *,compute(3)+aa
contains
elemental integer function compute(xx) result(rr)
integer,intent(in)::xx
rr=xx*xx+1
end function compute

end program
