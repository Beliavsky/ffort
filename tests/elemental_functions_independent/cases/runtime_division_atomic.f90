program elemental_test
implicit none
integer::aa(3)
aa(1)=1
aa(2)=0
aa(3)=2
print *,112
print *,compute(aa)
contains
elemental integer function compute(xx) result(rr)
integer,intent(in)::xx
rr=10/xx
end function compute

end program
