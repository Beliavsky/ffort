program elemental_test
implicit none
integer::aa(3)
aa(1)=1
aa(2)=2
aa(3)=3
print *,compute(aa)
contains
elemental integer function compute(xx) result(rr)
integer,intent(in)::xx
rr=helper(xx)+1
end function compute
pure integer function helper(xx) result(rr)
integer,intent(in)::xx
rr=xx*2
end function helper

end program
