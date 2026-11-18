module counter_state
implicit none
integer :: hits
contains
impure elemental integer function next(x) result(k)
integer,intent(in) :: x
hits=hits+1
k=x
end function next
subroutine bump(v)
integer,intent(inout) :: v
v=v+10
end subroutine bump
end module counter_state
program third_index_once
use counter_state
implicit none
integer :: aa(1,1,2),v
hits=0
aa=7
v=aa(1,1,next(2))
print *,v,hits
end program third_index_once
