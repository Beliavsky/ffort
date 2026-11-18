program elemental_test
implicit none

print *,991
contains
elemental integer function compute(xx) result(rr)
integer,intent(in)::xx
rr=helper(xx)
end function compute
integer function helper(xx) result(rr)
integer,intent(in)::xx
rr=xx+1
end function helper

end program
