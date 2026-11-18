program elemental_test
implicit none
integer::aa(3)
aa(1)=1
aa(2)=3
aa(3)=5
print *,combine(first=2,third=4,second=aa)
contains
elemental integer function combine(first,second,third) result(rr)
integer,intent(in)::third,first,second
rr=100*first+10*second+third
end function combine

end program
