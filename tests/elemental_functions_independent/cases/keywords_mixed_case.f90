program elemental_test
implicit none
integer::aa(3)
aa=3
print *,combine(2,ThIrD=4,SeCoNd=aa)
contains
elemental integer function combine(first,second,third) result(rr)
integer,intent(in)::third,first,second
rr=100*first+10*second+third
end function combine

end program
