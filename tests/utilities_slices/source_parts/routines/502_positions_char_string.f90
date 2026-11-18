function positions_char_string(string,char) result(ipos)
! return in ipos(:) the positions of char in string, where char is assumed to have length 1
character (len=*), intent(in)  :: string  ! string that is searched
character (len=*), intent(in)  :: char    ! character to look for in string
integer          , allocatable :: ipos(:) ! positions of char in string
logical                        :: tf(len(string))
integer                        :: i
forall (i=1:len(string)) tf(i) = string(i:i) == char
call set_alloc(true_pos(tf),ipos)
end function positions_char_string
!
