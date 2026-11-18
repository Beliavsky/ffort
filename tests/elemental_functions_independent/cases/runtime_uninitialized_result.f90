program elemental_test
implicit none
integer::aa(3)
aa(1)=1
aa(2)=2
aa(3)=3
print *,112
print *,compute(aa)
contains
elemental integer function compute(xx) result(rr)
integer,intent(in)::xx
if(xx/=2) rr=xx
end function compute

end program
