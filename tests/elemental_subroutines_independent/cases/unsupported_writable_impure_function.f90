program elemental_actions
implicit none
integer::aa,rr
aa=2
rr=compute(aa)
print *,aa,rr
contains
impure elemental integer function compute(xx) result(rr)
integer,intent(inout)::xx
xx=xx+1
rr=xx
end function compute

end program
