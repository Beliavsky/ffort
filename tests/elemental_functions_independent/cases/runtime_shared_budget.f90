program elemental_test
implicit none
integer::aa(40)
aa=3
print *,compute(aa)
contains
elemental integer function compute(xx) result(rr)
integer,intent(in)::xx
integer::ii
rr=xx
do ii=1,20
rr=rr+1
end do
end function compute

end program
