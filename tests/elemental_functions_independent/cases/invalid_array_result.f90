program elemental_test
implicit none

print *,991
contains
elemental function compute(xx) result(rr)
integer,intent(in)::xx
integer::rr(2)
rr=xx
end function compute

end program
