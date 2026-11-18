program purity_test
implicit none

print *,compute(4)
contains
recursive simple integer function compute(xx) result(rr)
integer, intent(in) :: xx
if(xx==0) then
rr=1
else
rr=xx*compute(xx-1)
end if
end function compute

end program
