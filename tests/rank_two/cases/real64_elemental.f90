program independent_ranktwo
implicit none
real(8) :: aa(2,2),bb(2,2)
aa(1,1)=0.0d0
aa(2,1)=1.0d0
aa(1,2)=2.0d0
aa(2,2)=-1.0d0
bb=log(exp(aa))+sqrt(abs(aa))
print *,bb,erfc(aa)
end program independent_ranktwo
