program elemental_actions
implicit none
integer::aa(30),bb(30)
aa=1
bb=compute(aa)
print *,bb
contains
impure elemental integer function compute(xx) result(rr)
integer,intent(in)::xx
rr=xx+10
end function compute

end program
