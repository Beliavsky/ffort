program elemental_test
implicit none
integer::aa(2)
aa=3
print *,compute(aa)
contains
elemental real(8) function compute(xx) result(rr)
integer,intent(in)::xx
rr=xx*0.25d0
end function compute

end program
