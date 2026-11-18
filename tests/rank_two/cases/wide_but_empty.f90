program independent_ranktwo
implicit none
integer :: aa(65536,0)
print *,size(aa),size(aa,1),size(aa,2)
print *,lbound(aa,1),ubound(aa,1),lbound(aa,2),ubound(aa,2)
aa=1
print *,aa
end program independent_ranktwo
