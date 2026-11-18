program elemental_test
implicit none
integer::aa(3)
print *,compute((aa))
contains
elemental integer function compute(xx) result(rr)
integer,intent(in)::xx
rr=7
end function compute

end program
