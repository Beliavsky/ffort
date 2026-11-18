program purity_test
implicit none

print *,compute(simple=4)
contains
simple integer function compute(simple) result(rr)
integer,intent(in)::simple
rr=simple+3
end function

end program
