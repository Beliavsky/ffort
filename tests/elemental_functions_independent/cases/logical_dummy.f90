program elemental_test
implicit none
logical::aa(3)
aa=.false.
aa(2)=.true.
print *,compute(aa)
contains
elemental logical function compute(xx) result(rr)
logical,intent(in)::xx
rr=.not.xx
end function compute

end program
