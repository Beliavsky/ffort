program elemental_test
implicit none
integer::aa(3)
aa(1)=1
aa(2)=3
aa(3)=5
print *,combine(second=aa,third=4,first=2)
contains
elemental integer function combine(first,second,third) result(rr)
integer,intent(in)::third,first,second
rr=100*first+10*second+third
end function combine

end program
