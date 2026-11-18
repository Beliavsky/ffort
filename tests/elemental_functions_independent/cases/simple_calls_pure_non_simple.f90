program elemental_test
implicit none

print *,helper(3)
contains
elemental integer function compute(xx) result(rr)
integer,intent(in)::xx
rr=xx*xx+1
end function compute
simple integer function helper(xx) result(rr)
integer,intent(in)::xx
rr=compute(xx)
end function helper

end program
