function match_category_string_scalar(xx,sym,sym_cat,categories) result(icat)
character (len=*), intent(in) :: xx
character (len=*), intent(in) :: sym(:),sym_cat(:) ! (n)
character (len=*), intent(in) :: categories(:)
integer                       :: icat
integer                       :: i,jcat,n
icat = 0
n = size(sym)
if (size(sym_cat) /= n) then
   write (*,*) "in match_category_string, size(sym), size(sym_cat)=",n,size(sym_cat)," must be equal, STOPPING"
   stop
end if
do i=1,n
   if (xx == sym(i)) then
      do jcat=1,size(categories)
         if (sym_cat(i) == categories(jcat)) then
            icat = jcat
            return
         end if
      end do
   end if
end do
end function match_category_string_scalar
!
