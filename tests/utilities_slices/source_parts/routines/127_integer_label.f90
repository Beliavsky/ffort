function integer_label(i,fmt_i) result(ilabel)
! return integer labels from i1 to i2 with format fmt_i
integer          , intent(in)           :: i
character (len=*), intent(in), optional :: fmt_i
character (len=20)                      :: ilabel
character (len=20)                      :: fmt_i_
call set_optional(fmt_i_,xdef="(i0)",xopt=fmt_i)
write (ilabel,fmt_i_) i
end function integer_label
!
