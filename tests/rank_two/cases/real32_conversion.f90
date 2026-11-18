program independent_ranktwo
implicit none
real :: aa(2,2)
integer :: bb(2,2)
aa(1,1)=-2.75
aa(2,1)=1.25
aa(1,2)=3.5
aa(2,2)=4.0
bb=aa
print *, bb
print *, real(bb)+0.5,sqrt(abs(aa)),int(aa)
end program independent_ranktwo
