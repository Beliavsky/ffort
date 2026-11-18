program elemental_test
implicit none
integer::aa(-2:0,4:5)
print *,size(compute(aa)),size(compute(aa),1),size(compute(aa),2)
print *,lbound(compute(aa),1),ubound(compute(aa),1),lbound(compute(aa),2),ubound(compute(aa),2)
contains
elemental integer function compute(xx) result(rr)
integer,intent(in)::xx
rr=xx*xx+1
end function compute

end program
