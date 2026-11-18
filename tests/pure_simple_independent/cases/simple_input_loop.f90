program purity_test
implicit none

print *,991
contains
simple integer function compute(xx) result(rr)
integer,intent(in)::xx
do xx=1,3
end do
rr=xx
end function compute

end program
