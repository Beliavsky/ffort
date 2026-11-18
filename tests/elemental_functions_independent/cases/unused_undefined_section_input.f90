program elemental_test
implicit none
integer::aa(5)
print *,compute(aa(5:1:-2))
contains
elemental integer function compute(xx) result(rr)
integer,intent(in)::xx
rr=7
end function compute

end program
