subroutine set_first_false(ival,tf,iflag)
! if any of tf(:) is not true, set ival to the corresponding value of iflag(:), or to the position of the first false element if iflag is not present
integer, intent(inout)        :: ival
logical, intent(in)           :: tf(:)
integer, intent(in), optional :: iflag(:)
integer                       :: ipos
ipos = first_false(tf)
if (ipos == 0) return
if (present(iflag)) then
   if (size(iflag) == size(tf)) then
      ival = iflag(ipos)
   else
      ival = -1
   end if
else
   ival = ipos
end if
end subroutine set_first_false
!
