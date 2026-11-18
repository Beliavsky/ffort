program elemental_actions
implicit none
integer::aa(3),rr
logical::mm(3)
aa(1)=1
aa(2)=2
aa(3)=3
mm=.false.
mm(2)=.true.
rr=sum(compute(aa),mask=mm)
print *,rr
contains
impure elemental integer function compute(xx) result(rr)
integer,intent(in)::xx
print *,xx
rr=xx+10
end function compute

end program
