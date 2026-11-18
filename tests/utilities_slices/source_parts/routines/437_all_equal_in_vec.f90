function all_equal_in_vec(vec) result(tf)
integer, intent(in) :: vec(:)
logical :: tf
integer :: i,n
n = size(vec)
tf = .true.
if (n < 2) return
do i=2,n
   if (vec(i) /= vec(i-1)) then
      tf = .false.
      return
   end if
end do
end function all_equal_in_vec
!
