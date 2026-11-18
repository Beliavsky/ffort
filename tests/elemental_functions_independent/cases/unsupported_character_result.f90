program elemental_test
implicit none

print *,compute(2)
contains
elemental function compute(xx) result(rr)
integer,intent(in)::xx
character(len=1)::rr
rr="a"
end function compute

end program
