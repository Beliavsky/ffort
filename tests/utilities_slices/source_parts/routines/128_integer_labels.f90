function integer_labels(i1,i2,fmt_i) result(ilabel)
! return integer labels from i1 to i2 with format fmt_i
integer          , intent(in)           :: i1,i2
character (len=*), intent(in), optional :: fmt_i
character (len=20)                      :: ilabel(i2-i1+1)
character (len=20)                      :: fmt_i_
integer                                 :: i,n
n = i2 - i1 + 1
call set_optional(fmt_i_,xdef="(i0)",xopt=fmt_i)
do i=1,n
   write (ilabel(i),fmt_i_) i1 + i - 1
end do
end function integer_labels
!
