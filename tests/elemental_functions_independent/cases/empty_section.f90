program elemental_test
implicit none
integer::aa(3)
print *,compute(aa(2:1))
print *,size(compute(aa(2:1)))
contains
elemental integer function compute(xx) result(rr)
integer,intent(in)::xx
error stop 77
rr=xx
end function compute

end program
