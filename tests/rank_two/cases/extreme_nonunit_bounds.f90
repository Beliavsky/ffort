program independent_ranktwo
implicit none
integer :: aa(-2147483647:-2147483646,2147483646:2147483647)
aa=3
aa(-2147483646,2147483647)=7
print *,aa
print *,lbound(aa,1),ubound(aa,1),lbound(aa,2),ubound(aa,2)
end program independent_ranktwo
