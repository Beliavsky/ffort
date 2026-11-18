subroutine write_words(label,words,fmt_c,outu)
character (len=*), intent(in)           :: label,words(:)
character (len=*), intent(in)           :: fmt_c
integer          , intent(in), optional :: outu
integer                                 :: i,outu_,nw
outu_ = default(istdout,outu)
nw = size(words)
write (outu_,fmt_c) trim(label),(trim(words(i)),i=1,nw)
end subroutine write_words
!
