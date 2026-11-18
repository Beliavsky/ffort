program purity_test
implicit none

print *,compute(4)
contains
simple integer function compute(xx) result(rr)
integer,value::xx
rr=xx*xx+1
end function compute

end program
