program section_oracle
implicit none
real :: aa(-1:2,3:5)
integer :: bb(2,2)
aa=1.25
aa(-1:2:2,3:5:2)=2.75
bb=aa(-1:2:2,3:5:2)
print *,aa,bb
print *,sqrt(aa(-1:2:2,3:5:2)),aa(-1:2:2,3:5:2)>2.0
end program section_oracle
