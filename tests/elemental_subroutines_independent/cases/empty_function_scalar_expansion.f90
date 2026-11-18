program elemental_actions
implicit none
integer::bb(0)
bb=compute(7)
print *,size(bb)
contains
impure elemental integer function compute(xx) result(rr)
integer,intent(in)::xx
print *,xx
rr=xx+10
end function compute

end program
