program independent_ranktwo
implicit none
integer :: aa(2,2),bb(-1:0,3:4),cc(2,2)
aa(1,1)=-5
aa(2,1)=0
aa(1,2)=3
aa(2,2)=8
bb=2
cc=max(abs(aa),bb)+min(aa,1)+mod(aa,2)
print *,cc
cc=aa*aa/2-3
print *,cc
print *, aa==bb,aa>0,aa<bb
end program independent_ranktwo
