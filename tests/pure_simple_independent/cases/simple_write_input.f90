program purity_test
implicit none

print *,991
contains
simple integer function compute(xx) result(rr)
integer,intent(in)::xx
xx=2
rr=xx
end function compute

end program
