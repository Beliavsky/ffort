subroutine write_vec(strings,fmt,prefix,suffix,outu,fmt_header,fmt_trailer,print_count)
! write trimmed strings(:) with format fmt and optional prefix and suffix to unit outu
character (len=*), intent(in)           :: strings(:)
character (len=*), intent(in)           :: fmt
character (len=*), intent(in), optional :: prefix,suffix,fmt_header,fmt_trailer
integer          , intent(in), optional :: outu
logical          , intent(in), optional :: print_count
integer                                 :: outu_,i,n
character (len=10)                      :: prefix_,suffix_
n       = size(strings)
prefix_ = default(nlen=10,def="",opt=prefix)
suffix_ = default(nlen=10,def="",opt=suffix)
outu_   = default(istdout,outu)
call write_format(fmt_header,outu_)
if (default(.false.,print_count)) write (outu_,"('count = ',i0)") n
! write (outu_,"(100(a,1x))") ("'" // trim(strings(i)) // "'",i=1,size(strings))
write (outu_,fmt=fmt) (trim(prefix_) // trim(strings(i)) // trim(suffix_),i=1,n)
call write_format(fmt_trailer,outu_)
end subroutine write_vec
!
