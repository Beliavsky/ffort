function combine_col_int(x1,x2) result(xmat)
! combine real vectors into a matrix
integer, intent(in) :: x1(:),x2(:)
integer             :: xmat(size(x1),2)
if (size(x1) == size(x2)) then
   xmat(:,1) = x1
   xmat(:,2) = x2
else
   write (*,*) mod_str,"size(x1), size(x2) =",size(x1),size(x2)," must be equal, stoppinG"
   stop
end if
end function combine_col_int
!
