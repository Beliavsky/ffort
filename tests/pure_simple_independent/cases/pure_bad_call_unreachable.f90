program purity_test
implicit none

print *,991
contains
pure integer function compute(xx) result(rr)
integer,intent(in)::xx
if(.false.) then
rr=helper(xx)
else
rr=xx
end if
end function compute
integer function helper(xx) result(rr)
integer, intent(in) :: xx
rr=xx
end function helper

end program
