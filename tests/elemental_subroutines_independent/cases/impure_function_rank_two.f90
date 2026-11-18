program elemental_actions
implicit none
integer::aa(2,2),bb(2,2)
aa(1,1)=11
aa(2,1)=12
aa(1,2)=21
aa(2,2)=22
bb=compute(aa)
print *,bb
contains
impure elemental integer function compute(xx) result(rr)
integer,intent(in)::xx
print *,xx
rr=xx+10
end function compute

end program
