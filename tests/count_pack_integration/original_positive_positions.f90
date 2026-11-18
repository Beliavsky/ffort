module original_utilities
implicit none
contains
function true_pos_func(tf) result(ipos)
! return in ipos the positions of the true elements in tf(:)
logical, intent(in) :: tf(:)
integer             :: ipos(count(tf))
integer             :: i,j
j = 0
do i=1,size(tf)
   if (tf(i)) then
      j = j + 1
      ipos(j) = i
   end if
end do
end function true_pos_func
!
function positive_int_vec(ivec) result(jvec)
integer, intent(in) :: ivec(:)
integer             :: jvec(count(ivec>0))
jvec = pack(ivec,ivec>0)
end function positive_int_vec
!
end module
program main
use original_utilities
implicit none
integer::empty(0),v(5)=[-2,1,0,3,-1]
print *,positive_int_vec(v)
print *,size(positive_int_vec([-2,0,-1]))
print *,sum(positive_int_vec(empty))
print *,positive_int_vec(v(5:1:-1))
print *,true_pos_func(positive_int_vec([-1,2,3])>2)
print *,positive_int_vec(positive_int_vec([-3,1,2])-1)
print *,positive_int_vec([-1,7])
end program
