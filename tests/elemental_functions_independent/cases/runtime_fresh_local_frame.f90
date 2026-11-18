program elemental_test
implicit none
integer::aa(2)
aa(1)=1
aa(2)=2
print *,compute(aa)
contains
elemental integer function compute(xx) result(rr)
integer,intent(in)::xx
integer::local
if(xx==1) local=8
rr=local
end function compute

end program
