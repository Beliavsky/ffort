program elemental_test
implicit none
integer::aa(2,3)
integer::dd
aa(1,1)=1
aa(2,1)=2
aa(1,2)=3
aa(2,2)=4
aa(1,3)=5
aa(2,3)=6
dd=2
print *,compute(sum(dim=dd,array=aa))
contains
elemental integer function compute(xx) result(rr)
integer,intent(in)::xx
rr=xx*xx+1
end function compute

end program
