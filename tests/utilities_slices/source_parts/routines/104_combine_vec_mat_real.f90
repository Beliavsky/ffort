function combine_vec_mat_real(xvec,xmat,idim,position) result(ymat)
! augment matrix xmat(:,:) by vector xvec(:) by adding either a row or column, at either the beginning or the end
real(kind=dp), intent(in) :: xvec(:)    ! (n)
real(kind=dp), intent(in) :: xmat(:,:)  ! (n1,n2)
integer      , intent(in) :: idim
character (len=*), intent(in) :: position
real(kind=dp), allocatable :: ymat(:,:)
integer :: n,n1,n2
character (len=*), parameter :: msg = mod_str // "combine_vec_mat, "
n   = size(xvec)
n1  = size(xmat,1)
n2  = size(xmat,2)
if (idim < 1 .and. idim > 2 .and. position /= "before" .and. position /= "after") then
   call set_alloc(xmat,ymat)
   return
end if
if (idim == 1) then ! add another row
   call assert(n == n2,msg // "size(xvec) /= size(xmat,2)",stop_error=.true.)
   allocate (ymat(n1+1,n2))
   if (position == "before") then
      ymat(1,:)  = xvec
      ymat(2:,:) = xmat
   else
      ymat(:n1,:) = xmat
      ymat(n1+1,:) = xvec
   end if
else ! add another column
   call assert(n == n1,msg // "size(xvec) /= size(xmat,1)",stop_error=.true.)
   allocate (ymat(n1,n2+1))
   if (position == "before") then
      ymat(:,1)    = xvec
      ymat(:,2:)   = xmat
   else
      ymat(:,:n2)  = xmat
      ymat(:,n2+1) = xvec
   end if
end if
end function combine_vec_mat_real
!
