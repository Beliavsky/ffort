program purity_test
implicit none

print *,991
contains
simple integer function compute(xx) result(rr)
integer,intent(in)::xx
if(helper(xx)>0) then
rr=1
else
rr=0
end if
end function compute
pure integer function helper(xx) result(rr)
integer, intent(in) :: xx
rr=xx
end function helper

end program
