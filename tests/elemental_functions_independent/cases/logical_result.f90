program elemental_test
implicit none
integer::aa(4)
aa(1)=0
aa(2)=1
aa(3)=2
aa(4)=3
print *,compute(aa)
contains
elemental logical function compute(xx) result(rr)
integer,intent(in)::xx
rr=xx>1
end function compute

end program
