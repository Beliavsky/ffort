program purity_test
implicit none

print *,compute(4)
contains
pure integer function compute(xx) result(rr)
integer, intent(in) :: xx
integer :: ii,acc
acc=0
do ii=1,xx
acc=acc+ii*ii
end do
rr=acc
end function compute

end program
