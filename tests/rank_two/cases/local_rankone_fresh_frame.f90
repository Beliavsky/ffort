program independent_ranktwo
implicit none
integer :: kk
print *,work(2),work(5)
contains
integer function work(xx) result(rr)
 integer,intent(in) :: xx
 integer :: local(-1:1)
 local=xx
 local(0)=xx+3
 rr=local(-1)+local(0)+local(1)
end function work
end program independent_ranktwo
