program independent_ranktwo
implicit none
integer :: kk
print *,array_result()
contains
function array_result() result(rr)
 integer :: rr(2,2)
 rr=1
end function array_result
end program independent_ranktwo
