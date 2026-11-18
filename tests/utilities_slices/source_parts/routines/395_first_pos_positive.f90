pure function first_pos_positive(vec) result(ipos)
integer, intent(in) :: vec(:)
integer :: ipos
integer :: i
ipos = 0
do i=1,size(vec)
   if (vec(i) > 0) then
      ipos = i
      return
   end if
end do
end function first_pos_positive
!
