program elemental_test
implicit none
integer::aa(5)
aa(1)=1
aa(2)=2
aa(3)=3
aa(4)=4
aa(5)=5
aa(2:5)=compute(aa(1:4))
print *,aa
contains
elemental integer function compute(xx) result(rr)
integer,intent(in)::xx
rr=xx*xx+1
end function compute

end program
