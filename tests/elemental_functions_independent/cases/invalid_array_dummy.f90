program elemental_test
implicit none

print *,991
contains
elemental integer function compute(xx) result(rr)
integer,intent(in)::xx(:)
rr=sum(xx)
end function compute

end program
