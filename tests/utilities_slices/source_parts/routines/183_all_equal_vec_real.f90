pure function all_equal_vec_real(xx,yy,tol,iexcl) result(tf)
! true if elements of xx and yy, excluding those in positions iexcl(:), are the same, using tolerance tol
real(kind=dp), intent(in)           :: xx(:),yy(:)
real(kind=dp), intent(in), optional :: tol
integer      , intent(in), optional :: iexcl(:)
logical                             :: tf
real(kind=dp)                       :: tol_
integer                             :: i
call set_optional_real(tol_,tiny_real,tol)
if (size(xx) /= size(yy)) then
   tf = .false.
   return
end if
if (present(iexcl)) then
   tf = .true.
   do i=1,size(xx)
      if ((i .notin. iexcl) .and. abs(xx(i)-yy(i)) > tol_) then
         tf = .false.
         exit
      end if
   end do
else
   tf = all(abs(xx-yy) <= tol_)
end if
end function all_equal_vec_real
!
