program elemental_test
implicit none
integer::aa(3),bb(3)
aa=2
bb=3
print *,dot_product(compute(aa),compute(bb))
contains
elemental integer function compute(xx) result(rr)
integer,intent(in)::xx
rr=xx*xx+1
end function compute

end program
