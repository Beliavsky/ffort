program elemental_test
implicit none
real::aa(3)
aa(1)=0.5
aa(2)=1.5
aa(3)=2.5
print *,compute(aa)
contains
elemental real function compute(xx) result(rr)
real,intent(in)::xx
rr=xx*0.5
end function compute

end program
