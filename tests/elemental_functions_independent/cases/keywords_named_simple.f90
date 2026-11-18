program elemental_test
implicit none

print *,compute(simple=4)
contains
simple elemental integer function compute(simple) result(rr)
integer,intent(in)::simple
rr=simple+3
end function compute

end program
