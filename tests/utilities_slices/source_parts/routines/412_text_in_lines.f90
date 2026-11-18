function text_in_lines(lines,text,case_sensitive) result(found)
! return .true. if text is found in any of lines(:)
character (len=*), intent(in) :: lines(:)
character (len=*), intent(in) :: text
logical, intent(in), optional :: case_sensitive
logical                       :: found
integer                       :: i
logical                       :: case_sensitive_
character (len=len(text))     :: text_lower
case_sensitive_ = default(.true.,case_sensitive)
found = .false.
if (case_sensitive_) then
   do i=1,size(lines)
      if (index(lines(i),text) /= 0) then
         found = .true.
         return
      end if
   end do
else
   text_lower = lower_case_str(text)
!   print*,"text_lower = '" // trim(text_lower) // "'" !! debug
!   stop !! debug
   do i=1,size(lines)
   !   if (index_case(lines(i),text,case_sensitive=.false.) /= 0) then
      if (index(lower_case_str(lines(i)),text_lower) /= 0) then
         found = .true.
         return
      end if
   end do
end if
end function text_in_lines
!
