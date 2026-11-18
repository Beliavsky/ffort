program elemental_actions
implicit none

print *,compute(2)
contains
impure elemental integer function compute(xx) result(rr)
integer,intent(in)::xx
rr=xx+10
end function compute

end program
