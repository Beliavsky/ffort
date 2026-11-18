pure function first_row_all_true(tf) result(irow)
logical, intent(in) :: tf(:,:)
integer             :: irow
integer             :: i
irow = 0
do i=1,size(tf,1)
   if (all(tf(i,:))) then
      irow = i
      exit
   end if
end do
end function first_row_all_true
!
