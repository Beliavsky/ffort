pure function last_row_all_true(tf) result(irow)
logical, intent(in) :: tf(:,:)
integer             :: irow
integer             :: i
irow = 0
do i=size(tf,1),1,-1
   if (all(tf(i,:))) then
      irow = i
      exit
   end if
end do
end function last_row_all_true
!
