program purity_test
implicit none

print *,991
contains
pure integer function compute(xx) result(rr)
integer,intent(in)::xx
integer::ii
rr=0
do ii=1,helper(xx)
rr=rr+1
end do
end function compute
pure integer function helper(xx) result(rr)
integer, intent(in) :: xx
rr=xx
end function helper

end program
