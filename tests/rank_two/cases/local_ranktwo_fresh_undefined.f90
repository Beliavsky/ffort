program independent_ranktwo
implicit none
integer :: kk
print *,work(1)
print *,work(2)
contains
integer function work(xx) result(rr)
 integer,intent(in) :: xx
 integer :: local(2,2)
 if (xx==1) local=7
 rr=local(2,2)
end function work
end program independent_ranktwo
