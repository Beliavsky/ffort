program independent_ranktwo
implicit none
integer :: aa(2,3),bb(-1:0,4:6),i
aa=9
bb=4
bb(0,5)=aa(2,3)+8
print *, aa,bb
end program independent_ranktwo
