program elemental_test
implicit none
integer::aa(2)
aa=3
print *,helper(aa)
contains
pure elemental integer function compute(xx) result(rr)
integer,intent(in)::xx
rr=xx*xx+1
end function compute
pure integer function helper(xx) result(rr)
integer,intent(in)::xx(:)
rr=sum(compute(xx))
end function helper

end program
