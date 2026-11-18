program independent_ranktwo
implicit none
integer :: aa(-1:0,5:7)
aa=2
call first(aa)
print *,aa
contains
subroutine first(xx)
 integer,intent(inout) :: xx(3:,-2:)
 call second(xx)
 xx(4,0)=xx(4,0)+7
end subroutine first
subroutine second(yy)
 integer,intent(inout) :: yy(-4:,7:)
 yy=yy*3
 yy(-4,8)=19
end subroutine second
end program independent_ranktwo
