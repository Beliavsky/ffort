program elemental_test
implicit none
integer::aa(-1:0,4:6)
aa(-1,4)=7
aa(0,4)=8
aa(-1,5)=9
aa(0,5)=10
aa(-1,6)=11
aa(0,6)=12
print *,compute(aa)
contains
elemental integer function compute(xx) result(rr)
integer,intent(in)::xx
rr=xx*xx+1
end function compute

end program
