program independent_ranktwo
implicit none
integer :: aa(2,2)
aa=4
print *,work(aa),work(aa+1)
contains
integer function work(xx) result(rr)
 integer,intent(in) :: xx(:,:)
 integer :: local(2,2)
 local=xx*2
 rr=local(1,1)+local(2,2)
end function work
end program independent_ranktwo
