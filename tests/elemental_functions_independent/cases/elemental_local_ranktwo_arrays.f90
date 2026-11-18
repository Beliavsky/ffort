program elemental_test
implicit none
integer::aa(3)
aa(1)=1
aa(2)=2
aa(3)=3
print *,compute(aa)
contains
elemental integer function compute(xx) result(rr)
integer,intent(in)::xx
integer::local(2,3)
local=xx
rr=sum(local)
end function compute

end program
