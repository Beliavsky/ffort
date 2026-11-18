pure function last_true(tf) result(i1)
! return position of last true element of tf(:), 0 if no true elements
logical, intent(in) :: tf(:)
integer             :: i1
integer             :: i
i1 = 0
do i=size(tf),1,-1
   if (tf(i)) then
      i1 = i
      return
   end if
end do
end function last_true
!
