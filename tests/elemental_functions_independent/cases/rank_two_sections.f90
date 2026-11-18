program elemental_test
implicit none
integer::aa(3,4)
aa(1,1)=11
aa(2,1)=12
aa(3,1)=13
aa(1,2)=21
aa(2,2)=22
aa(3,2)=23
aa(1,3)=31
aa(2,3)=32
aa(3,3)=33
aa(1,4)=41
aa(2,4)=42
aa(3,4)=43
print *,compute(aa(3:1:-2,4:1:-2))
contains
elemental integer function compute(xx) result(rr)
integer,intent(in)::xx
rr=xx*xx+1
end function compute

end program
