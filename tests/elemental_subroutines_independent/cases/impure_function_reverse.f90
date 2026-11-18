program elemental_actions
implicit none
integer::aa(3),bb(3)
aa(1)=1
aa(2)=2
aa(3)=3
bb=compute(aa(3:1:-1))
print *,bb
contains
impure elemental integer function compute(xx) result(rr)
integer,intent(in)::xx
print *,xx
rr=xx+10
end function compute

end program
