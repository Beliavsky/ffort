subroutine get_data(label,sym,xx,yy)
! get yy(:) from column in xx(:,:) corresponding to label(:)
character (len=*)     , intent(in)            :: label,sym(:)
real(kind=dp)         , intent(in) , target   :: xx(:,:)
real(kind=dp), pointer, intent(out), optional :: yy(:)
integer                                       :: i,icol_
icol_ = match_string_scalar(label,sym)
if (icol_ == 0) then
   write (*,*) "in util_mod::get_data, available symbols are",(" '" // trim(sym(i)) // "'",i=1,size(sym))
   write (*,*) "could not read data for '" // trim(label) // "', STOPPING"
   stop
end if
if (present(yy)) yy => xx(:,icol_)
end subroutine get_data
!
