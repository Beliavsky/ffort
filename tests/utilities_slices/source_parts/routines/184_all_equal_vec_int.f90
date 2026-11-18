pure function all_equal_vec_int(xx,yy,iexcl) result(tf)
! true if elements of xx and yy, excluding those in positions iexcl(:), are the same
integer      , intent(in)           :: xx(:),yy(:)
integer      , intent(in), optional :: iexcl(:)
logical                             :: tf
integer                             :: i
if (size(xx) /= size(yy)) then
   tf = .false.
   return
end if
if (present(iexcl)) then
   tf = .true.
   do i=1,size(xx)
      if ((i .notin. iexcl) .and. xx(i) /= yy(i)) then
         tf = .false.
         exit
      end if
   end do
else
   tf = all(xx == yy)
end if
end function all_equal_vec_int
!
