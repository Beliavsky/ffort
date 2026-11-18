function lookup_char_matrix(xx,yy,xkey,ydefault) result(yvalue)
! return the values in rows of yy(:,:) corresponding to xkeys(:) in xx(:), for xx(:,)), yy(:), xkey of type character
character (len=*), intent(in)           :: xx(:),yy(:,:)
character (len=*), intent(in)           :: xkey(:)
character (len=*), intent(in), optional :: ydefault ! default value of yvalue(:,:) when xkey(:) not found in xx(:)
character (len=len(yy))                 :: yvalue(size(xkey),size(yy,2))
integer                                 :: ikey,imatch,n
n = size(xx)
if (size(yy,1) /= n) then
   write (*,*) "in lookup, size(xx), size(yy,1) =",n,size(yy)," must be equal, STOPPING"
   stop
end if
if (present(ydefault)) then
   yvalue = ydefault
else
   yvalue = ""
end if
do_key: do ikey=1,size(xkey)
   imatch = match_string_scalar(xkey(ikey),xx)
   if (imatch /= 0) yvalue(ikey,:) = yy(imatch,:)
end do do_key
end function lookup_char_matrix
!
