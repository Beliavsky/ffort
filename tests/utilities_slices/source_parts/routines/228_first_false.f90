pure function first_false(tf) result(i1)
! return the location of the first false element in tf(:), 0 if all .true.
logical, intent(in) :: tf(:)
integer             :: i1
integer             :: i
i1 = 0
do i=1,size(tf)
   if (.not. tf(i)) then
      i1 = i
      return
   end if
end do
end function first_false
!
