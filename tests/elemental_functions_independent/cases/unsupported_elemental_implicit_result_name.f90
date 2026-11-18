program elemental_test
implicit none

print *,compute(3)
contains
elemental integer function compute(xx)
integer,intent(in)::xx
compute=xx+4
end function

end program
