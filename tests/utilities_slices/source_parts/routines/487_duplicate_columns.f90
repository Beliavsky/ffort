function duplicate_columns(xx) result(idup)
! return in idup(i) the column of xx(:,:) that is the same as xx(:,i), 0 if no other column is the same
real(kind=dp), intent(in) :: xx(:,:)
integer                   :: idup(size(xx,2))
integer                   :: nrows,ncol,icol,jcol
nrows = size(xx,1)
ncol  = size(xx,2)
idup  = 0
do_icol: do icol=2,ncol
   do jcol=1,icol-1
      if (all(xx(:,icol) == xx(:,jcol))) then
         idup(icol) = jcol
         cycle do_icol
      end if
   end do
end do do_icol
end function duplicate_columns
!
