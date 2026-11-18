program elemental_actions
implicit none
integer::aa(2),bb(2)
aa(1)=1
aa(2)=2
bb=compute(compute(aa))
print *,bb
contains
impure elemental integer function compute(xx) result(rr)
integer,intent(in)::xx
print *,xx
rr=xx+10
end function compute

end program
