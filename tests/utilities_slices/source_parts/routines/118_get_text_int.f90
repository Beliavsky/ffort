subroutine get_text_int(in_unit,text,ii)
! read integer ii from text
integer          , intent(in)  :: in_unit
character (len=*), intent(out) :: text
integer          , intent(out) :: ii
read (in_unit,"(a)") text
read (text,*) ii
end subroutine get_text_int
!
