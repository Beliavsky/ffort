program elemental_actions
implicit none
integer::rr
rr=compute(3)
print *,rr
contains
integer elemental impure function compute(xx) result(rr)
integer,intent(in)::xx
rr=xx+10
end function compute

end program
