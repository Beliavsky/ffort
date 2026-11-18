program elemental_actions
implicit none
integer::aa
aa=2
print *,compute(aa)
contains
impure elemental integer function compute(xx) result(rr)
integer,intent(in)::xx
print *,xx
rr=xx+10
end function compute

end program
