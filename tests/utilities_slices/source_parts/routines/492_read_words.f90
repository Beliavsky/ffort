subroutine read_words(iu,words,echo)
! read an integer, allocate words(:), and read one word per line
integer          , intent(in)               :: iu
character (len=*), intent(out), allocatable :: words(:)
logical          , intent(in) , optional    :: echo
integer                                     :: i,n
logical                                     :: echo_
echo_ = default(.false.,echo)
read (iu,*) n
allocate (words(n))
do i=1,n
   read (iu,*) words(i)
   if (echo_) write (*,"(a)") trim(words(i))
end do
end subroutine read_words
!
