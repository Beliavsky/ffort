program elemental_test
implicit none

print *,991
contains
pure elemental pure integer function compute(xx) result(rr)
integer,intent(in)::xx
rr=xx
end function compute

end program
