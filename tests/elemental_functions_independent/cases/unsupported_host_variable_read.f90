program elemental_test
implicit none
integer::host
host=4
print *,compute(2)
contains
elemental integer function compute(xx) result(rr)
integer,intent(in)::xx
rr=xx+host
end function compute

end program
