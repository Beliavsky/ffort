subroutine check_included_vec_int(ii,jj)
! check that each element in ii(:) is in jj(:), stopping otherwise
integer, intent(in) :: ii(:),jj(:)
integer             :: i,ni,nbad
ni   = size(ii)
nbad = 0
do i=1,ni
   if (ii(i) .notin. jj) then
      nbad = nbad + 1
      write (*,*) "in check_included, i, ii(i) =",i,ii(i)," not in jj"
   end if
end do
if (nbad > 0) stop
end subroutine check_included_vec_int
!
