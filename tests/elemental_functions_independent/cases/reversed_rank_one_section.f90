program elemental_test
implicit none
integer::aa(-2:3)
aa(-2)=1
aa(-1)=2
aa(0)=3
aa(1)=4
aa(2)=5
aa(3)=6
print *,compute(aa(3:-2:-2))
contains
elemental integer function compute(xx) result(rr)
integer,intent(in)::xx
rr=xx*xx+1
end function compute

end program
