program elemental_actions
implicit none
integer::bb(3)
bb=compute(7)
print *,bb
contains
impure elemental integer function compute(xx) result(rr)
integer,intent(in)::xx
print *,xx
rr=xx+10
end function compute

end program
