program elemental_test
implicit none
integer::aa(2,3)
aa(1,1)=1
aa(2,1)=2
aa(1,2)=3
aa(2,2)=4
aa(1,3)=5
aa(2,3)=6
print *,take(compute(aa))
contains
elemental integer function compute(xx) result(rr)
integer,intent(in)::xx
rr=xx*xx+1
end function compute
pure integer function take(xx) result(rr)
integer,intent(in)::xx(:,:)
rr=sum(xx)
end function take

end program
