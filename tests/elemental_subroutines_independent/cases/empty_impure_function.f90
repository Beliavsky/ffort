program elemental_actions
implicit none
integer::aa(0),bb(0)
bb=compute(aa)
print *,size(bb)
contains
impure elemental integer function compute(xx) result(rr)
integer,intent(in)::xx
print *,xx
rr=xx+10
end function compute

end program
