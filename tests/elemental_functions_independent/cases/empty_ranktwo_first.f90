program elemental_test
implicit none
integer::aa(0,3)
print *,compute(aa)
print *,size(compute(aa))
print *,size(compute(aa),1),size(compute(aa),2)
contains
elemental integer function compute(xx) result(rr)
integer,intent(in)::xx
error stop 77
rr=xx
end function compute

end program
