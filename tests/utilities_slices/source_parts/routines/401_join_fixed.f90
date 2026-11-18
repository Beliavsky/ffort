function join_fixed(words,nlen) result(text)
character (len=*), intent(in)    :: words(:)
integer          , intent(in)    :: nlen
character (len=size(words)*nlen) :: text
integer                          :: i
character (len=100)              :: fmt_t
! print*,"in join_fixed, size(words), nlen=",size(words),nlen
write (fmt_t,"('(10000a',i0,')')") nlen
write (text,fmt_t) (trim(words(i)),i=1,size(words))
end function join_fixed
!
