program rankthree
implicit none
real(8) :: aa(2,1,2)
logical :: ll(2,1,2)
aa=4.0d0
aa(2,1,2)=9.0d0
print *,sqrt(aa)+0.5d0
ll=aa>5.0d0
print *,ll,.not.ll
end program rankthree
