function match_category_string_vec(xx,sym,sym_cat,categories) result(icat)
character (len=*), intent(in) :: xx(:)
character (len=*), intent(in) :: sym(:),sym_cat(:) ! (n)
character (len=*), intent(in) :: categories(:)
integer                       :: icat(size(xx))
integer                       :: i
do i=1,size(xx)
   icat(i) = match_category_string_scalar(xx(i),sym,sym_cat,categories)
end do
end function match_category_string_vec
!
