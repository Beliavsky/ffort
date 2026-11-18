function variable_names(n,prefix,suffix,imin) result(names)
! construct variable names from integers
integer          , intent(in)           :: n
character (len=*), intent(in), optional :: prefix
character (len=*), intent(in), optional :: suffix
integer          , intent(in), optional :: imin
character (len=100)                     :: names(n)
integer                                 :: i,j,imin_
imin_ = default(1,imin)
names = ""
do i=1,n
   j = imin_ + i - 1
   if (present(prefix)) names(i) = prefix
   names(i) = trim(names(i)) // str_int(j)
   if (present(suffix)) names(i) = trim(names(i)) // suffix
end do
end function variable_names
!
