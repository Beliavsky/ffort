subroutine write_trim_vec(strings,prefix,suffix,outu)
character (len=*), intent(in)           :: strings(:)
character (len=*), intent(in), optional  :: prefix,suffix
integer          , intent(in), optional :: outu
integer                                 :: outu_,i
character (len=10)                      :: prefix_,suffix_
prefix_ = default(nlen=10,def="'",opt=prefix)
suffix_ = default(nlen=10,def="'",opt=prefix)
outu_   = default(istdout,outu)
! write (outu_,"(100(a,1x))") ("'" // trim(strings(i)) // "'",i=1,size(strings))
write (outu_,"(100(a,1x))") (trim(prefix_) // trim(strings(i)) // trim(suffix_),i=1,size(strings))
end subroutine write_trim_vec
!
