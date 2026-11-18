subroutine write_xname_yname(xname,yname,iu,skip_present,skip_missing,cdelim)
character (len=*), intent(in), optional :: xname,yname
integer          , intent(in), optional :: iu
logical          , intent(in), optional :: skip_present,skip_missing
character (len=*), intent(in), optional :: cdelim
integer                                 :: iu_
character (len=10)                      :: cdelim_
iu_     = default(istdout,iu)
cdelim_ = default("vs.",cdelim)
if (present(xname) .and. present(yname)) then
   if (present_and_true(skip_present)) write (iu_,*)
   write (iu_,*) trim(xname) // " " // trim(cdelim_) // " " // trim(yname)
else
   if (present_and_true(skip_missing)) write (iu_,*)
end if
end subroutine write_xname_yname
!
