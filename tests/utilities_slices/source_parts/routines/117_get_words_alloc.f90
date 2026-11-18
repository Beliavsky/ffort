subroutine get_words_alloc(in_unit,words)
! allocate and read a vector of words
! the line of text contains the number of words followed by the words
integer          , intent(in)  :: in_unit
character (len=10000)          :: text
character (len=*), allocatable, intent(out) :: words(:)
integer                        :: ierr,nw
read (in_unit,"(a)",iostat=ierr) text
read (text,*) nw
nw = max(nw,0)
allocate (words(nw))
read (text,*) nw,words
end subroutine get_words_alloc
!
