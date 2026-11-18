program independent_ranktwo
implicit none
integer :: aa(2,2)
aa=3
call revise(aa(2,1),aa(1,2))
print *,aa
contains
subroutine revise(xx,yy)
 integer,intent(inout) :: xx
 integer,intent(out) :: yy
 xx=xx+10
 yy=xx+7
end subroutine revise
end program independent_ranktwo
