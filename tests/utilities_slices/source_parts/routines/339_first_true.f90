pure function first_true(tf) result(i1)
! return the location of the first true element in tf(:), 0 if none true
logical, intent(in) :: tf(:)
integer             :: i1
integer             :: i
i1 = 0
do i=1,size(tf)
   if (tf(i)) then
      i1 = i
      return
   end if
end do
end function first_true
!
