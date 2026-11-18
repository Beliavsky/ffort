program independent_ranktwo
implicit none
integer :: aa(-2:0,7:8)
print *, size(aa),size(aa,1),size(aa,2)
print *, lbound(aa,1),ubound(aa,1),lbound(aa,2),ubound(aa,2)
print *, size(aa+1),ubound(aa+1,2)
end program independent_ranktwo
