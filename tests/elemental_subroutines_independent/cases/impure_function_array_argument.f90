program elemental_actions
implicit none
integer::aa(3),rr
aa(1)=1
aa(2)=2
aa(3)=3
rr=reduce(compute(aa))
print *,rr
contains
impure elemental integer function compute(xx) result(rr)
integer,intent(in)::xx
print *,xx
rr=xx+10
end function compute
pure integer function reduce(xx) result(rr)
integer,intent(in)::xx(:)
rr=sum(xx)
end function reduce

end program
