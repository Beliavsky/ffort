subroutine split_string(string,delim,words,adjustl_words)
! split string by delim
character (len=*)                , intent(in)  :: string
character (len=*)                , intent(in)  :: delim
character (len=*)   , allocatable, intent(out) :: words(:)
logical             , optional   , intent(in)  :: adjustl_words
call set_alloc(split(string,delim,adjustl_words=adjustl_words),words)
end subroutine split_string
!
