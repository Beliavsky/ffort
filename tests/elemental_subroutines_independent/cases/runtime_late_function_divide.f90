program elemental_actions
implicit none
integer::aa(3),bb(3)
aa(1)=1
aa(2)=0
aa(3)=2
bb=compute(aa)
print *,bb
contains
impure elemental integer function compute(xx) result(rr)
integer,intent(in)::xx
print *,xx
rr=10/xx
end function compute

end program
